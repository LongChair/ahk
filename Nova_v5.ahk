
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
;#include whales.ahk
#include discord.ahk
#include attack.ahk
#include scan.ahk
#include collect.ahk
#include farm.ahk

#NoEnv
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
#SingleInstance Force
SetTitleMatchMode 2
#WinActivateForce


Loop
{
	global NovaConfig
	global PlayerName
	
	; global Nova config file
	NovaPath =  %A_ScriptDir%\nova.json
	PastebinPath =  %A_ScriptDir%\pastebin.json

	NovaConfig := GetObjectFromJSON(NovaPath)
	if (NovaConfig == "") 
	{
		LOG("ERROR : Failed to read nova.json", 2)
		return
	}
		
	; get pasteBinconfig
	if !StorePasteBinConfig(NovaConfig.PASTEBIN.link, PastebinPath)
	{
		LOG("ERROR : Failed to save pastebin configuration into file.", 2)
		LOG("Using existing file.")
	}
	
	PasteBinConfig := GetObjectFromJSON(PastebinPath)
	if (PasteBinConfig == "") 
	{
		LOG("ERROR : Failed to read pastebin.json", 2)
		return
	}

	
	For i, player in NovaConfig.GENERAL.Players
	{
		if (PasteBinConfig.Players[player.name].enable)
		{
			PlayerName := player.name
			LOG(Format("Player {1} is enabled, proceeding.", player.name))
			DoAccount(player)
		}
		else
		{
  		   LOG(Format("Player {1} is disabled, skipping.", player.name))
		   Sleep, 10000
		}
	}
	
} 

;*******************************************************************************
; StorePasteBinConfig : Store the provided pastebin configuration Link to a file
; Link : pastebin Link
; File : output file
;*******************************************************************************
StorePasteBinConfig(Link, FileName)
{
	global NovaConfig
	
	pbin := new pastebin(NovaConfig.PASTEBIN.user, NovaConfig.PASTEBIN.password)
	PasteBinConfig := pbin.getPastedata(Link)
	
	if (Substr(PasteBinConfig, 1,1) != "{")
		return 0
		
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
DoAccount(player)
{	
	global PlayerConfig
	
	Log("Nova Empire Automation version " . Version . " - (c) LongChair 2019")

	; Read Configureation
    Log("Reading Configuration...")
	
	FullPath :=  Format("{1}\{2}.json", A_ScriptDir, player.name)
    PlayerConfig := GetObjectFromJSON(FullPath)
	if (PlayerConfig == "") 
	{
		LOG(Format("ERROR : Failed to read {1}.json, exiting", player.name), 2)
		return
	}
	
    DoSequence(player)
     
    ; Write Configuration
    Log("Writing Configuration...")
    SaveObjectToJSON(PlayerConfig, FullPath)
	
    
    Log("Waiting...")
    Sleep, LoopTime
}
;*******************************************************************************
; DoSequence : Main loop of the program
;*******************************************************************************
DoSequence(player)
{
    
    global FrigatesAmount, NumFreeMecas, MaxPlayerMecas
	global PlayerName, Farming, Farming3D, FarmingMulti
    global IterationTime, LastStartTime
	global Ressources, Pirates, Ressources_BlackList, Pirates_BlackList
	global LoopPeriod
	global CurrentSystem
	global RunMode, Sequence
	global FarmingMulti
	
	global PlayerConfig
	
    Fail := 1
    StartTime := A_TickCount

	; wait for period to be done
	if  (PlayerConfig.COUNTERS.LastStartTime > A_TickCount)
		PlayerConfig.COUNTERS.LastStartTime := A_TickCount - (LoopPeriod * 1000)

	MinTime := PlayerConfig.COUNTERS.LastStartTime + (1000 * LoopPeriod)
	
	; wait for it
	if (MinTime > A_TickCount)
	{
		WaitTime_ms := (MinTime - A_TickCount)
		LOG(Format("Waiting for period completion : {1:i} s...", WaitTime_ms / 1000))
		Sleep, % WaitTime_ms
	}
	
	LOG(Format("Loop period was : {1:i} s...", (StartTime - PlayerConfig.COUNTERS.LastStartTime) / 1000))
	PlayerConfig.COUNTERS.LastStartTime := StartTime

	
	
    Log("------------------ Starting Sequence in " .  A_ScriptDir . " for " . player.name . " -------------------")	
	
    if LaunchNova()
    {	
		LoadContext()

		if (!LoadScanInfo())
			goto TheEnd

		;test()
		
		SendDiscord(Format(":arrow_forward: Started and running in **{1}** mode", PlayerConfig.GENERAL.runmode))
			   
		config := GetObjectFromJSON("runmodes\" . PlayerConfig.GENERAL.runmode . ".json")
		if (config == "")
		{
			LOG(Format("ERROR : Failed to read {1}.json file, stopping",PlayerConfig.GENERAL.runmode) 2)
			goto TheEnd
		}
				
		; process the config object
		if (!ProcessOperations(config.operations))
		{
			LOG(Format("ERROR : Failed to process command lists, stopping", 2))
			goto TheEnd
		}

    }
    
    TheEnd:
    SaveContext()
    NovaScreenShot()
	SendDiscord(Format(":stop_button: Stopped Sequence for {1} ", player.name))
	
	Fail := 1
    StopNova(Fail)
    Log("------------------------------ Stopping Sequence for " . player.name . " ------------------------------")
}

;*******************************************************************************
; LaunchNova : Will Launch nova, that is strt it by clikcing on Bluestacks
; icon and all the necessary clicks until main screen is on 
;*******************************************************************************
LaunchNova()
{
    global AppX, AppY, AppW, AppH
    global MainWinX, MainWinY, MainWinW, MainWinH, WinCenterX, WinCenterY, WinBorderX, WinBorderY
	global Window_ID
	global PlayerConfig
	
	SetTitleMatchMode 2
	SetControlDelay 1
	SetWinDelay 0
	SetKeyDelay -1
	SetBatchLines -1
	
	
	Log("***** Launching Emulator...")
	CommandLine := PlayerConfig.GENERAL.commandline 
	Run, %CommandLine%
	while !WinExist(PlayerConfig.GENERAL.windowname)
	{
		Sleep, 1000
	}
    Log("Emulator Launched...")
	
    ; Activate BlueStacks Window
	Window_ID := WinExist(PlayerConfig.GENERAL.windowname)
    WinActivate, ahk_id %Window_ID%
    WinMove, ahk_id %Window_ID%,, AppX, AppY, AppW, AppH
    WinGetPos, MainWinX, MainWinY, MainWinW, MainWinH, ahk_id %Window_ID%
	WinCenterX := (MainWinW - WinBorderX) / 2 + WinBorderX
	WinCenterY := (MainWinH - WinBorderY) / 2 + WinBorderY
   
 
	  ; check CEG button
    Log("Waiting for Nova Main screen ...")   
	Loop, 20
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
				Loop, Parse, % PlayerConfig.GENERAL.username
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
				Loop, Parse, % PlayerConfig.GENERAL.password
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
		while (NovafindClick("Buttons\close_nova.png", 50, "w100 n1", FoundX, FoundY, 0, 0, 1200, 50) 
		OR NovafindClick("Buttons\close_nova_alt.png", 50, "w100 n1", FoundX, FoundY, 0, 0, 1200, 50))
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
		Count := GetObjectProperty(op, "count", 1)
        if (op.name=="REPEAT")
        {
            Loop, % Count
            {
                if (!ProcessOperations(op.operations))
                    return 0
            }
        }
        else
          Loop, % Count
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
	global Context
	
	if (!IsActive(op))
		return 1
		
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
                                
        case "NOTIFY" :
           SendDiscord(Format(op.message, Context.Stats[op.param1], Context.Stats[op.param2], Context.Stats[op.param3]))
		   
		case "WAIT" :
           Sleep, op.value
		   
		case "TEST" :
			
			
		case "FARM" :
			if (!farm(op)) 
			{
				Log ("ERROR : Failed farming !", 2)
				return 0
			}
			
		default :
			Log (Format("ERROR : Unknown operation {1} !", op.name), 2)
			return 0
    }
    
    return 1
}




; test() : just a test function
test()
{
	global ScanInfo
	global AreaX1, AreaY1, AreaX2, AreaY2
	
	NovaFindClick(Format("targets\void.png", ScanType), ScanInfo.levels[key], "e n0 dx", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)          
}

