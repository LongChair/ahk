
; This script automates a few non fun tasks in Nova empire

#Include  %A_ScriptDir% 
#include globals.ahk
#include libs\FindClick.ahk
#include libs\PasteBin.ahk
#Include utils.ahk
#include screens.ahk
#include resources.ahk
#include pirates.ahk
#include free_resources.ahk
#include build_ships.ahk


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
	

	
	; global Nova config file
    FullPath =  %A_ScriptDir%\Nova.ini
	IniPath =  %A_ScriptDir%\PasteBin.ini
    
    ; Read Player Count
    IniRead, PlayerCount, %FullPath%, GENERAL, PlayerCount, 0
	IniRead, PasteBinConfigLink, %FullPath%, PASTEBIN, PasteBinConfigLink, ""
	IniRead, PasteBinUser, %FullPath%, PASTEBIN, PasteBinUser, ""
    IniRead, PasteBinPassword, %FullPath%, PASTEBIN, PasteBinPassword, ""
	
	; get pasteBinconfig
	if !StorePasteBinConfig(PasteBinConfigLink, IniPath)
	{
		LOG("ERROR : Failed to save pastebin configuration into ini file.", 2)
		return
	}
	
	
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
	
    Fail := 1
    StartTime := A_TickCount

	; wait for period to be done
	if  (LastStartTime > A_TickCount)
		LastStartTime := A_TickCount - (LoopPeriod * 1000)
	if (Farming)
		MinTime := LastStartTime + (1000 * LoopPeriod)
	Else
		MinTime := LastStartTime + (1000 * 3 * 60)
	
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
	;LoadBlackLists()
	
    if LaunchNova()
    {   			
        Log("========= CheckFreeResources Start =========")
        if !CheckFreeResources()
        {
            Log ("ERROR : Failed to collect free resources !", 2)
            Goto TheEnd
        }
        Log("========= CheckFreeResources End   =========")
	
    
		Log("========= BuildFrigates Start =========")
        if !BuildFrigates(FrigatesAmount)
        {
            Log ("ERROR : Failed to build frigates !", 2)
            Goto TheEnd
        }
        Log("========= BuildFrigates End   =========")
		                      
		; check if tank is fresh
        if (Farming Or Farming3D)
			if (!FarmingMulti)
				TankFresh := IsTankFresh()
			Else
			{
				;if (!RepairAllFleets())
				;{
				;	Log ("ERROR : Failed to repair fleets !", 2)
				;	Goto TheEnd
				;}
				
				TankFresh := 1
			}
			

		; scan pirates ressources in system if farming
        if (Farming and TankFresh)
        {
			if (!ScanResourcesInSystem(""))
			{
				Log ("ERROR : Failed to scan system ressources !", 2)
				Goto TheEnd
			}
			
			Log("Filtering with blacklists and cleaning up ...")
			;RemoveObosoleteBlackList(Ressources_BlackList, Ressources)
			;RemoveObosoleteBlackList(Pirates_BlackList, Pirates)
			;FilterListwithBlackList(Ressources, Ressources_BlackList)
			;FilterListwithBlackList(Pirates, Pirates_BlackList)
			Log(Format("We have {1} pirates and {2} ressources left...", Pirates.Length(), Ressources.Length()))
			Log(Format("We have {1} pirates and {2} ressources in blacklist...", Pirates_BlackList.Length(), Ressources_BlackList.Length()))
		}
		
		Log("========= getFreeMecas Start =========")
		if (!Farming3D)
		{
			if !GetAvailableMecaCount(NumFreeMecas)
			{
				Log ("ERROR : Failed to get available mecas count !", 2)
				Goto TheEnd
			}
			Log("We have " . NumFreeMecas . "/" . MaxPlayerMecas . " mecas left")
			StartFreeMecas := NumFreeMecas
			
			if (NumFreeMecas = 0 and Farming = 0)
			{
				Log("Looks like we have no more mecas, skipping")
				Goto DoSequence_Complete
			}
		}
		Log("========= getFreeMecas End =========")
		
		if (Farming and TankFresh)
		{
  
			if (FarmingMulti)
			{
			
				if (!FarmPiratesMulti(25))
				{
					Log ("ERROR : Failed to farm pirates !", 2)
					Goto TheEnd
				}
			}
			Else
			{
				if (!FarmPirates(25))
				{
					Log ("ERROR : Failed to farm pirates !", 2)
					Goto TheEnd
				}
			}
	
        }
        Else
        {
			if (Farming3D)
			{
				FarmPirates3D(20)
			}
			Else
			{
				if (NumFreeMecas > 0 )
				{					
					CollectResources()
				}
				Else
				{
					LOG("No free meca, skipping, collect...")
				}
			}
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
    global FreeResCollected, OtherResCollected, FrigatesBuilt, FrigatesAmount, LoopTime 
	global PlayerName
	global KilledCount
	global Farming, Farming3D, FarmingMulti
	global CurrentSystem
	global LastStartTime
	global FrigateType
    
    FullPath =  %A_ScriptDir%\%PlayerName%.ini
	IniPath =  %A_ScriptDir%\PasteBin.ini
	
    
    ; Counters
    IniRead, FreeResCollected, %FullPath%, COUNTERS, FreeResCollected, 0
    IniRead, OtherResCollected, %FullPath%, COUNTERS, OtherResCollected , 0
    IniRead, FrigatesBuilt, %FullPath%, COUNTERS, FrigatesBuilt, 0
	IniRead, LastStartTime, %FullPath%, COUNTERS, LastStartTime, 0
    
    ;IniRead, FrigatesAmount, %FullPath%, PARAMETERS, FrigatesAmount, 0
	IniRead, FrigatesAmount, %IniPath%, FRIGATES, %PlayerName%, 0
    IniRead, LoopTime, %FullPath%, PARAMETERS, LoopTime, 300000
	IniRead, Farming, %FullPath%, PARAMETERS, Farming, 0
	IniRead, Farming3D, %FullPath%, PARAMETERS, Farming3D, 0
	IniRead, FarmingMulti, %FullPath%, PARAMETERS, FarmingMulti, 0
	
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
	IniRead, MaxPlayerMecas, %FullPath%, GENERAL, MaxPlayerMecas, ""
	IniRead, FrigateType, %FullPath%, GENERAL, FrigateType, ""
	
	; ressources Priority
	IniRead, ResPriority1, %FullPath%, PRIORITIES, ResPriority1, "MINE"
	IniRead, ResPriority2, %FullPath%, PRIORITIES, ResPriority2, "CRYSTALS"
	IniRead, ResPriority3, %FullPath%, PRIORITIES, ResPriority3, "ALLIUM"
	
    ; stats
    IniRead, KilledCount, %FullPath%, STATS, KilledCount, 0
	IniRead, Helped, %FullPath%, STATS, Helped, 0
	
	; Get the current system we are in
	IniRead, CurrentSystem, %FullPath%, SYSTEMS, Current, ""
   
    
}

;*******************************************************************************
; WriteConfig : Writes the configuration file
;*******************************************************************************
WriteConfig()
{
    global FreeResCollected, OtherResCollected, FrigatesBuilt, FrigatesAmount, LoopTime
	global PlayerName
    global KilledCount, Helped
	global Farming, Farming3D, FarmingMulti
	global LastStartTime
	
    FullPath =  %A_ScriptDir%\%PlayerName%.ini
    
    ; Counters
    IniWrite, %FreeResCollected%, %FullPath%, COUNTERS, FreeResCollected
    IniWrite, %OtherResCollected%, %FullPath%, COUNTERS, OtherResCollected
    IniWrite, %FrigatesBuilt%, %FullPath%, COUNTERS, FrigatesBuilt
	IniWrite, %LastStartTime%, %FullPath%, COUNTERS, LastStartTime
    
    IniWrite, %FrigatesAmount%, %FullPath%, PARAMETERS, FrigatesAmount
    IniWrite, %LoopTime%, %FullPath%, PARAMETERS, LoopTime
	IniWrite, %Farming%, %FullPath%, PARAMETERS, Farming
	IniWrite, %Farming3D%, %FullPath%, PARAMETERS, Farming3D
	IniWrite, %FarmingMulti%, %FullPath%, PARAMETERS, FarmingMulti
	
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
}

;*******************************************************************************
; LaunchNova : Will Launch nova, that is strt it by clikcing on Bluestacks
; icon and all the necessary clicks until main screen is on 
;*******************************************************************************
LaunchNova()
{
    global AppX, AppY, AppW, AppH
    global MainWinX, MainWinY, MainWinW, MainWinH, WinCenterX, WinCenterY, WinBorderX, WinBorderY
    global CommandLine, WindowName
	global Window_ID
	
	SetTitleMatchMode 2
	SetControlDelay 1
	SetWinDelay 0
	SetKeyDelay -1
	SetBatchLines -1
	
	
    if (!WinExist(WindowName))
    {
        Log("***** Launching BlueStacks...")
        Run, %CommandLine%
        sleep, 1000
        WinWait, %WindowName%,, 100
    
        Log("Waiting for BlueStacks to be fully started...")
    }
    else
    {
        Log("BlueStacks is launched")
    }
    
    ; Activate BlueStacks Window
	Window_ID := WinExist(WindowName)
    WinActivate, ahk_id %Window_ID%
    WinMove, ahk_id %Window_ID%,, AppX, AppY, AppW, AppH
    WinGetPos, MainWinX, MainWinY, MainWinW, MainWinH, ahk_id %Window_ID%
	WinCenterX := (MainWinW - WinBorderX) / 2 + WinBorderX
	WinCenterY := (MainWinH - WinBorderY) / 2 + WinBorderY
   
    ; click home tab
    Log("Waiting for BlueStacks home tab ...")
    if !NovaFindClick("buttons\bs_home.png", 60, "w60000 n1")
    {
        Log("ERROR : Failed to select home screen, exiting...", 2)
        return 0
    }
    
    ; click nova app
	
    Log("Waiting for BlueStacks Nova icon ...")
    if !NovaFindClick("buttons\nova_icon_big.png", 60, "w60000 n0")
    {
        Log("ERROR : Failed to find nova app icon, exiting...", 2)
        return 0
    }
	
	sleep, 1000
    if !NovaFindClick("buttons\nova_icon_big.png", 60, "w1000 n1")
    {
        Log("ERROR : Failed to start nova app icon, exiting...", 2)
        return 0
    }

    
    ; click nova tab
    Log("***** Launching Nova Empire...")
    Log("Waiting for BlueStacks Nova tab ...")
    if !NovaFindClick("buttons\nova_icon.png", 60, "w5000 n1")
    {
        Log("ERROR : Failed to find nova tab, exiting...", 2)
        return 0
    }
    
	  ; check CEG button
    Log("Waiting for Nova Main screen ...")   
    if !NovaFindClick("buttons\ceg.png", 30, "w1000 n0", FoundX, FoundY, 1700, 40, 1960, 150)
    {
		
		Log("Waiting for Nova welcome screen ...")
		if !NovaFindClick("buttons\cross.png", 40, " w70000 n1")
		{
			Log("No welcome screen found.")
		}

		Log("Waiting for Nova news screen ...")
		if !NovaFindClick("buttons\news_cross.png", 0, " w5000 n1")
		{
			Log(" No news screen found.")
		}
			
		; check CEG button
		Log("Waiting for Nova Main screen ...")   
		if !NovaFindClick("buttons\ceg.png", 30, "w1000 n0", FoundX, FoundY, 1700, 40, 1960, 150)
		{
			Log("ERROR : Couldn't find CEG on start screen...", 2)
			return 0
		}
	}
    
    Log("***** Nova is up and running.")
    return 1
}

;*******************************************************************************
; StopNova : Will Stop nova by closing it in blue stacks
;*******************************************************************************
StopNova(CloseBluestacks := 1)
{
	global Window_ID, WindowName 
 
    if (!CloseBluestacks)
    {
        Log("Closing Nova ...")
        
        Log("Waiting for BlueStacks Nova tab ...")
        while (NovaFindClick("buttons\nova_icon.png", 30, "w500 n1 Stay"))
        {
            Log("Closing Nova tab ...")
            if !NovaFindClick("buttons\tab_cross.png", 60, "w1000 n1")
            {
                Log("ERROR : Failed to find nova tab cross to close, exiting...", 2)
                CloseBluestacks := 1
                goto StopNova_Close
            }

        }
        Log("Nova is closed.")
    }
    
    
StopNova_Close:    
    if (CloseBluestacks)
    {
        ; Now Close BlueStacks
        Log("Closing BlueStacks...")
        WinClose, %WindowName%
        sleep, 2000
        
        ; Wait for it to close
        Log("Waiting for BlueStacks to close...")    
        while WinExist(WindowName)
        {
			; Click on the confirm button
			if !NovaFindClick("buttons\yes.png", 70, "w20000 n1")
			{
				Log("ERROR : Could not find exit confirm button, exiting...", 2)
				
				; try to click Button
				NovaLeftMouseClick(980, 580) 
			}
			Else
			{
				break
			}
        }
        
        Log("BlueStacks is closed.")
    }
}