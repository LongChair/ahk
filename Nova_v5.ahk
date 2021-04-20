
; This script automates a few non fun tasks in Nova empire

#Include  %A_ScriptDir% 
#include globals.ahk
#include libs\FindClick.ahk
#include libs\PasteBin.ahk
#include libs\JSON.ahk
#Include utils.ahk
#include screens.ahk
#include resources.ahk
#include pirates.ahk
#include piratesv2.ahk
#include elitesv2.ahk
#include free_resources.ahk
#include build_ships.ahk
#include whales.ahk
#include discord.ahk

#NoEnv
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
#SingleInstance Force
SetTitleMatchMode 2
#WinActivateForce


Loop
{
	global PasteBinUser, PasteBinPassword
	global discord
	global DiscordWebhooKURL
	
	; global Nova config file
    FullPath =  %A_ScriptDir%\Nova.ini
	IniPath =  %A_ScriptDir%\PasteBin.ini
    
    ; Read Player Count
    IniRead, PlayerCount, %FullPath%, GENERAL, PlayerCount, 0
	
    IniRead, PasteBinConfigLink, %FullPath%, PASTEBIN, PasteBinConfigLink, ""
	IniRead, PasteBinUser, %FullPath%, PASTEBIN, PasteBinUser, ""
    IniRead, PasteBinPassword, %FullPath%, PASTEBIN, PasteBinPassword, ""
	
    IniRead, DiscordToken, %FullPath%, DISCORD, DiscordToken
	IniRead, DiscordWebhooKURL, %FullPath%, DISCORD, DiscordWebhooKURL
	
	; get pasteBinconfig
	;if !StorePasteBinConfig(PasteBinConfigLink, IniPath)
	;{
	;	LOG("ERROR : Failed to save pastebin configuration into ini file.", 2)
	;	return
	;}
	
	
	; Loops players
	PlayerIndex := 1
	Loop, %PlayerCount%
	{
		
		
		; Get player name
		Key := "Player" . PlayerIndex
		IniRead, Player, %FullPath%, PLAYERS, %Key%, 0
		
		; check if player name is Active
		IniRead, PlayerEnable, %IniPath%, ENABLE, %Player%, -1
		
		if PlayerEnable
		{
		   LOG(Format("Player {1} is enabled, proceeding.", Player))
		   DoAccount(Player)
		  
		   LOG(Format("Player {1} was processed in {2:i} seconds.", Player, ElapsedTime / 1000))
		}
		Else
		{
  		   LOG(Format("Player {1} is disabled, skipping.", Player))
		   Sleep, 10000
		}
		
		PlayerIndex := PlayerIndex + 1
	}
} 

;*******************************************************************************
; StorePasteBinConfig : Store the provided pastebin configuration Link to a file
; Link : pastebin Link
; File : output file
;*******************************************************************************
StorePasteBinConfig(Link, FileName)
{
	global PasteBinUser, PasteBinPassword
	
	pbin := new pastebin(PasteBinUser, PasteBinPassword)
	PasteBinConfig := pbin.getPastedata(Link)
	
	file := FileOpen(FileName, "w")
	if !IsObject(file)
	{
		Log("ERROR : Can't open " %FileName% " for writing.", 2 )
		return 0
	}
	
	file.Write(PasteBinConfig)
	file.Close()
	
	return 1
}


;*******************************************************************************
; DoAccount : Does the whole program for given account
;*******************************************************************************
DoAccount(Account)
{
	global PlayerName
	global StartH, StartM, EndH, EndM
	
	PlayerName := Account
	
	Log("Nova Empire Automation version " . Version . " - (c) LongChair 2019")

	; Read Configureation
    Log("Reading Configuration...")
    ReadConfig()
	
    DoSequence()
     
    ; Write Configuration
    Log("Writing Configuration...")
    WriteConfig()
    
    Log("Waiting...")
    Sleep, LoopTime
}
;*******************************************************************************
; DoSequence : Main loop of the program
;*******************************************************************************
DoSequence()
{
    
    global FrigatesAmount, NumFreeMecas, MaxPlayerMecas
	global PlayerName, Farming, Farming3D, FarmingMulti
    global IterationTime, LastStartTime
	global Ressources, Pirates, Ressources_BlackList, Pirates_BlackList
	global LoopPeriod
	global CurrentSystem
	global RunMode, Sequence
	global FarmingMulti
	
    Fail := 1
    StartTime := A_TickCount

	; wait for period to be done
	if  (LastStartTime > A_TickCount)
		LastStartTime := A_TickCount - (LoopPeriod * 1000)

	MinTime := LastStartTime + (1000 * LoopPeriod)
	
	; wait for it
	if (MinTime > A_TickCount)
	{
		WaitTime_ms := (MinTime - A_TickCount)
		LOG(Format("Waiting for period completion : {1:i} s...", WaitTime_ms / 1000))
		Sleep, % WaitTime_ms
	}
	
	LOG(Format("Loop period was : {1:i} s...", (StartTime - LastStartTime) / 1000))
	LastStartTime := StartTime

	
	
    Log("------------------ Starting Sequence in " .  A_ScriptDir . " for " . PlayerName . " -------------------")	
	
    if LaunchNova()
    {	
		SendDiscord(Format(":arrow_forward: Started and running in **{1}** mode", RunMode))
		
        ; reads the config file text
		FileRead json_str, RunMode . ".json"
        if (json_str="")
        {
            LOG(Format("ERROR : Failed to read {1}.json file, stopping", 2)
            goto TheEnd
        }
        
        ; parse the json string
        config := JSON.Load(json_str)
        
        ; process the config object
        if (!ProcessOperations(config.operations))
        {
            LOG(Format("ERROR : Failed to process command lists, stopping", 2)
            goto TheEnd
        }

DoSequence_Complete:	
		; compute iteration time
		ElapsedTime := A_TickCount - StartTime
		IterationTime := (ElapsedTime / 1000)
		   
        ; logs the summuary of the iteration
		Summuary := GetSummuary()
        Log(Format("`r`n{1}", Summuary), 1)
		
		; paste it to pastebin
		pbin := new pastebin(PasteBinUser, PasteBinPassword)
		pbin.paste(Summuary, Format("Nova for {3} at {1}:{2}", A_Hour, A_Min, PlayerName), "autohotkey", "1H", 2)
        Fail := 0
		
		;SaveBlackLists()
    }
    
    TheEnd:
	SendDiscord(Format(":stop_button: Stopped Sequence for {1} ", PlayerName))
	Fail := 1
    StopNova(Fail)
    Log("------------------------------ Stopping Sequence for " . PlayerName . " ------------------------------")
}

;*******************************************************************************
; GetSummuary : Gets the Summuary string
;*******************************************************************************
GetSummuary()
{
    global FreeResCollected, OtherResCollected, FrigatesBuilt, FrigatesAmount
	global NumFreeMecas, StartFreeMecas
	global FreeResCount, PossibleRes, MaxFreeRes
	global ScanAvailMine, ScanAvailAllium, ScanAvailCrystals, ScanMiningMecas, ScanCrystalingMecas, ScanAlliumingMecas
	global ResPriority1, ResPriority2, ResPriority3
	global IterationTime, Helped
	
	Summurary := ""
	Summuary := Summuary . Format("-==================== SUMMUARY at {1}:{2} ==({3})==========-`r`n", A_Hour, A_Min, FormatSeconds(IterationTime))  
	Summuary := Summuary . Format(" - MECAS :`r`n")
	Summuary := Summuary . Format("   * Free mecas at start         : {1}`r`n", StartFreeMecas)
	Summuary := Summuary . Format("   * Free mecas at end           : {1}`r`n", NumFreeMecas)
	Summuary := Summuary . Format("   * Resource with Priority #1   : {1}`r`n", ResPriority1)
	Summuary := Summuary . Format("   * Resource with Priority #2   : {1}`r`n", ResPriority2)
	Summuary := Summuary . Format("   * Resource with Priority #3   : {1}`r`n", ResPriority3)
	Summuary := Summuary . Format("`r`n")
    Summuary := Summuary . Format(" - SCAN :`r`n")
	Summuary := Summuary . Format("   * Available Mine              : {1}`r`n", ScanAvailMine)
	Summuary := Summuary . Format("   * Available Allium            : {1}`r`n", ScanAvailAllium)
	Summuary := Summuary . Format("   * Available Crystals          : {1}`r`n", ScanAvailCrystals)
	Summuary := Summuary . Format("   * Mining Mecas                : {1}`r`n", ScanMiningMecas)
	Summuary := Summuary . Format("   * Crystaling Mecas            : {1}`r`n", ScanCrystalingMecas)
	Summuary := Summuary . Format("   * Alliuming Mecas             : {1}`r`n", ScanAlliumingMecas)
	Summuary := Summuary . Format("`r`n")
	Summuary := Summuary . Format(" - GLOBAL STATS :`r`n")
	Summuary := Summuary . Format("   * Free resources collected    : {1}/{2}`r`n", FreeResCollected, MaxFreeRes)
	Summuary := Summuary . Format("   * Regular resources collected : {1}`r`n", OtherResCollected)
	Summuary := Summuary . Format("   * Frigates built              : {1}/{2}`r`n", FrigatesBuilt, FrigatesAmount)
    Summuary := Summuary . Format("   * Killed pirates              : {1}`r`n", KilledCount)
	Summuary := Summuary . Format("   * Alliance Helps              : {1}`r`n", Helped)
	Summuary := Summuary . Format("`r`n")
	Summuary := Summuary . Format(" - FREE RESSOURCES :`r`n")
	
	for i, res in PossibleRes
	{
		Summuary := Summuary . Format(" 	* {1} x {2}`r`n", FreeResCount[i], PossibleRes[i])
	}
	
	return Summuary
}
;*******************************************************************************
; ReadConfig : Reads the configuration file
;*******************************************************************************
ReadConfig()
{
	global FreeResCount, PossibleRes
    global FreeResCollected, OtherResCollected, FrigatesBuilt, FrigatesAmount, LoopTime, EliteKill
	global PlayerName
	global KilledCount
	global Farming, Farming3D, FarmingMulti, FarmingElites
	global CurrentSystem
	global LastStartTime
	global LastWhalekillTime
	global FrigateType
    global RunMode, Sequence
	global UserName, PassWord
	global WhaleKillCount, MaxWhaleKillCount
	
    FullPath =  %A_ScriptDir%\%PlayerName%.ini
	IniPath =  %A_ScriptDir%\PasteBin.ini
	
    
    ; Counters
    IniRead, FreeResCollected, %FullPath%, COUNTERS, FreeResCollected, 0
    IniRead, OtherResCollected, %FullPath%, COUNTERS, OtherResCollected , 0
    IniRead, FrigatesBuilt, %FullPath%, COUNTERS, FrigatesBuilt, 0
	IniRead, LastStartTime, %FullPath%, COUNTERS, LastStartTime, 0
	IniRead, LastWhalekillTime, %FullPath%, COUNTERS, LastWhalekillTime, 0
	IniRead, WhaleKillCount, %FullPath%, COUNTERS, WhaleKillCount, 0
	IniRead, MaxWhaleKillCount, %FullPath%, COUNTERS, MaxWhaleKillCount, 0
	IniRead, EliteKill, %FullPath%, COUNTERS, EliteKill, 0
	
    
    ;IniRead, FrigatesAmount, %FullPath%, PARAMETERS, FrigatesAmount, 0
	IniRead, FrigatesAmount, %IniPath%, FRIGATES, %PlayerName%, 0
    IniRead, LoopTime, %FullPath%, PARAMETERS, LoopTime, 300000
	IniRead, Farming, %FullPath%, PARAMETERS, Farming, 0
	IniRead, Farming3D, %FullPath%, PARAMETERS, Farming3D, 0
	IniRead, FarmingMulti, %FullPath%, PARAMETERS, FarmingMulti, 0
    IniRead, FarmingElites, %FullPath%, PARAMETERS, FarmingElites, 0
	
    
	
	
	; Free resource counters
	for i, res in PossibleRes
	{
		Key := "FreeRes" . i
		IniRead, Value, %FullPath%, FREE_RES, %Key%, 0
		FreeResCount[i] := Value
	}
	
	; General info
	IniRead, CommandLine, %FullPath%, GENERAL, CommandLine, ""
	IniRead, WindowName, %FullPath%, GENERAL, WindowName, ""
	IniRead, UserName, %FullPath%, GENERAL, UserName, ""
	IniRead, PassWord, %FullPath%, GENERAL, PassWord, ""
	IniRead, MaxPlayerMecas, %FullPath%, GENERAL, MaxPlayerMecas, ""
	IniRead, FrigateType, %FullPath%, GENERAL, FrigateType, ""
	IniRead, RunMode, %FullPath%, GENERAL, RunMode, ""
	IniRead, Sequence, %FullPath%, GENERAL, Sequence, ""
	
	
	; ressources Priority
	IniRead, ResPriority1, %FullPath%, PRIORITIES, ResPriority1, "MINE"
	IniRead, ResPriority2, %FullPath%, PRIORITIES, ResPriority2, "CRYSTALS"
	IniRead, ResPriority3, %FullPath%, PRIORITIES, ResPriority3, "ALLIUM"
	
    ; stats
    IniRead, KilledCount, %FullPath%, STATS, KilledCount, 0
	IniRead, Helped, %FullPath%, STATS, Helped, 0
	
	; Get the current system we are in
	IniRead, CurrentSystem, %FullPath%, SYSTEMS, Current, ""
   
	LoadFleetPosFromFile(Format("{1}\{2}-Fleets.ini", A_ScriptDir, PlayerName))
	
	. read the work frame
	IniRead, StartH, %FullPath%, TIME, StartH, 0
	IniRead, StartM, %FullPath%, TIME, StartM, 0
	IniRead, EndH, %FullPath%, TIME, EndH, 0
	IniRead, EndM, %FullPath%, TIME, EndM, 0
}

;*******************************************************************************
; WriteConfig : Writes the configuration file
;*******************************************************************************
WriteConfig()
{
    global FreeResCollected, OtherResCollected, FrigatesBuilt, FrigatesAmount, LoopTime, EliteKill
	global PlayerName
    global KilledCount, Helped
	global Farming, Farming3D, FarmingMulti
	global LastStartTime
	global LastWhalekillTime
	global WhaleKillCount, MaxWhaleKillCount
	
    FullPath =  %A_ScriptDir%\%PlayerName%.ini
    
    ; Counters
    IniWrite, %FreeResCollected%, %FullPath%, COUNTERS, FreeResCollected
    IniWrite, %OtherResCollected%, %FullPath%, COUNTERS, OtherResCollected
    IniWrite, %FrigatesBuilt%, %FullPath%, COUNTERS, FrigatesBuilt
	IniWrite, %LastStartTime%, %FullPath%, COUNTERS, LastStartTime
	IniWrite, %LastWhalekillTime%, %FullPath%, COUNTERS, LastWhalekillTime
	IniWrite, %WhaleKillCount%, %FullPath%, COUNTERS, WhaleKillCount
	IniWrite, %MaxWhaleKillCount%, %FullPath%, COUNTERS, MaxWhaleKillCount
	IniWrite, %EliteKill%, %FullPath%, COUNTERS, EliteKill
    
    IniWrite, %FrigatesAmount%, %FullPath%, PARAMETERS, FrigatesAmount
    IniWrite, %LoopTime%, %FullPath%, PARAMETERS, LoopTime
	IniWrite, %Farming%, %FullPath%, PARAMETERS, Farming
	IniWrite, %Farming3D%, %FullPath%, PARAMETERS, Farming3D
	IniWrite, %FarmingMulti%, %FullPath%, PARAMETERS, FarmingMulti
    IniWrite, %FarmingElites%, %FullPath%, PARAMETERS, FarmingElites
	
	; Free resource counters
	for i, res in PossibleRes
	{
		Value := FreeResCount[i]
		Key := "FreeRes" . i
		IniWrite, %Value%, %FullPath%, FREE_RES, %Key%
	}
	
	; ressources Priority
	IniWrite, %ResPriority1%, %FullPath%, PRIORITIES, ResPriority1
	IniWrite, %ResPriority2%, %FullPath%, PRIORITIES, ResPriority2
	IniWrite, %ResPriority3%, %FullPath%, PRIORITIES, ResPriority3
    
    ; stats
	IniWrite, %KilledCount%, %FullPath%, STATS, KilledCount
	IniWrite, %Helped%, %FullPath%, STATS, Helped
	
	SaveFleetPosToFile(Format("{1}\{2}-Fleets.ini", A_ScriptDir, PlayerName))
	
}

;*******************************************************************************
; LaunchNova : Will Launch nova, that is strt it by clikcing on Bluestacks
; icon and all the necessary clicks until main screen is on 
;*******************************************************************************
LaunchNova()
{
    global AppX, AppY, AppW, AppH
    global MainWinX, MainWinY, MainWinW, MainWinH, WinCenterX, WinCenterY, WinBorderX, WinBorderY
    global CommandLine, WindowName, Emulator
	global Window_ID
	
	SetTitleMatchMode 2
	SetControlDelay 1
	SetWinDelay 0
	SetKeyDelay -1
	SetBatchLines -1
	
	
	Log("***** Launching Emulator...")
	Run, %CommandLine%
	while !WinExist(WindowName)
	{
		Sleep, 1000
	}
    Log("Emulator Launched...")
	
    ; Activate BlueStacks Window
	Window_ID := WinExist(WindowName)
    WinActivate, ahk_id %Window_ID%
    WinMove, ahk_id %Window_ID%,, AppX, AppY, AppW, AppH
    WinGetPos, MainWinX, MainWinY, MainWinW, MainWinH, ahk_id %Window_ID%
	WinCenterX := (MainWinW - WinBorderX) / 2 + WinBorderX
	WinCenterY := (MainWinH - WinBorderY) / 2 + WinBorderY
   
 
	  ; check CEG button
    Log("Waiting for Nova Main screen ...")   
	Loop, 15
	{
		if (!NovaFindClick("buttons\ceg.png", 60, "w5000 n0", FoundX, FoundY, 1700, 40, 1960, 150))
		{
			 if (NovaFindClick("buttons\game_login.png", 50, "w1000 n1", FoundX, FoundY, 610, 230, 1270, 870))
			 {
				Log("Found Login menu...")
				
				if (!NovaFindClick("buttons\login_connexion.png", 50, "w3000 n0", FoundX, FoundY, 610, 230, 1270, 870))
				{
					Log("ERROR : Failed to wait for login prompt, exiting...", 2)
					return 0
				}
				
				Log("Entering UserName...")
				Sleep, 3000
				NovaLeftMouseClick(910,350)
				if (!NovaFindClick("buttons\OK_input.png", 50, "w3000 n0", FoundX, FoundY, 1650, 950, 1820, 1050))
				{
					Log("ERROR : Failed to wait for input zone, exiting...", 2)
					return 0
				}
				
				Sleep, 1000
				Loop, Parse, UserName
				{
   				  Send %A_LoopField%
				  Sleep, 100
				}
				Send, {Enter}

				Log("Entering Password...")
				Sleep, 3000
				NovaLeftMouseClick(910,460)
				if (!NovaFindClick("buttons\OK_input.png", 50, "w3000 n0", FoundX, FoundY, 1700, 990, 1820, 1050))
				{
					Log("ERROR : Failed to wait for input zone, exiting...", 2)
					return 0
				}
				Sleep, 1000
				Loop, Parse, PassWord
				{
				  if InStr(A_LoopField ,"#") then
					Send {#}
				  else
					Send %A_LoopField%
				  Sleep, 100
				}
				Send, {Enter}
				
				if (!NovaFindClick("buttons\login_connexion.png", 50, "w3000 n1", FoundX, FoundY, 610, 230, 1270, 870))
				{
					Log("ERROR : Failed to find connexion button, exiting...", 2)
					return 0
				}

				Goto LaunchNova_Running		
			 }
			 
		}
		Else
		{
			Goto LaunchNova_Running
		}
	}
	
	Log("ERROR : Failed to wait for CEG on start screen, exiting...", 2)
	return 0
	
LaunchNova_Running:
    Log("***** Nova is up and running.")
	
	; we need to make the cross get away	
	Count := 0
	while (!NovafindClick("Buttons\apercu.png", 30, "w1000 n1"))
	{
		if (NovafindClick("Buttons\player.png", 50, "w1000 n1"))
		{
			Sleep, 500
			Goto LaunchNova_Continue
		}
		Else
		{
			Count := Count + 1
		}
		
		If (Count > 50)
		{
			Log("ERROR : Failed to wait for player screen, exiting...", 2)
			return 0
		}
	}
	
	
LaunchNova_Continue:
	; now escape from player Screen
	NovaEscapeClick()
	
	; and click the cross
	NovafindClick("Buttons\start_cross.png", 30, "w3000 n1")
	Log("Nova Init sequence complete.", 2)
	
    return 1
}

;*******************************************************************************
; StopNova : Will Stop nova by closing it in blue stacks
;*******************************************************************************
StopNova(CloseBluestacks := 1)
{
	global WindowName 
  
	; Wait for it to close
	
	if (0)
	{		
		Log("Waiting for BlueStacks to close...")    
		while WinExist(WindowName)
		{
			; Now Close BlueStacks
			Log("Closing Emulator...")
			WinClose, %WindowName%	
			sleep, 1000
		}
		Log("Emulator is closed.")
	}
	Else
	{
		Log("Closing Nova Empire...")
		while (NovafindClick("Buttons\close_nova.png", 50, "w100 n1", FoundX, FoundY, 0, 0, 600, 50))
		{
			NovaLeftMouseClick(FoundX +50, FoundY)
			sleep, 1000
		}
		Log("Nova Empire is closed.")

	}	

}

;*******************************************************************************
; ProcessOperations : Will process the full json sequence
;*******************************************************************************
ProcessOperations(ops)
{
    For i,op in ops
    {
        if (op.name=="repeat")
        {
            Loop, % op.count
            {
                if (!ProcessOperations(op.operations))
                    return 0
            }
        }
        else
          Loop, % op.count
          {
              if (!DoOperation(op))
                    return 0
          }
    }
    
    return 1
}

;*******************************************************************************
; DoOperation : Will do the given operation name
;*******************************************************************************
DoOperation(op)
{
    Switch op.name
    {
        case "RESSOURCES" :
            if !CheckFreeResources()
            {
                Log ("ERROR : Failed to collect free resources !", 2)
                return 0
            }
                
        case "BUILD" :
            if !BuildShips(FrigatesAmount)
            {
                Log ("ERROR : Failed to build ships !", 2)
                return 0
            }
                                
        case "FARMING_ELITES_V2" :
            if (!FarmElites_v2(1, 1))
            {
                Log ("ERROR : Failed to farm Elites !", 2)
                return 0
            }
            
        case "FARMING_KRAKEN_V2" :
            if (!FarmElites_v2(1, 2))
            {
                Log ("ERROR : Failed to farm Krakens !", 2)
                return 0
            }
            
        case "FARMING_MULTI_1", "FARMING_MULTI_2" , "FARMING_MULTI_3":

            switch RunMode
            {
                case "FARMING_MULTI_1":                 
                    FleetsSpan := Object( 1, 6)
                case "FARMING_MULTI_2":
                    FleetsSpan := Object( 1, 3, 4, 6)
                default:
                    FleetsSpan := Object( 1, 2, 3, 4, 5, 6)
            }

            if (!FarmPirates_v2(FleetsSpan))
            {
                Log ("ERROR : Failed to farm pirates !", 2)
                return 0
            }
            
        case "WHALE_ASSIST" :
            if (!Whale_Assist())
            {
                Log ("ERROR : Failed assist on whales !", 2)
                return 0
            }                    
            
        case "FARMING_WHALES" :
            if (!Whale_Farming())
            {
                Log ("ERROR : Failed farming whales !", 2)
               return 0
            }
            
        case "NOTIFY" :
           SendDiscord(op.message)
    }
    
    return 1
}
