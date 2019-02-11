; Nova automation  LongChair 2019
; This script automates a few non fun tasks in Nova empire

#Include  %A_ScriptDir% 
#include globals.ahk
#include libs\FindClick.ahk
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


Log("Nova Empire Automation version " . Version . " - (c) LongChair 2019")

Loop
{
    ;LaunchNova()
	
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
    
    global FrigatesAmount, NumFreeMecas
    
    Log("------------------------------Starting Sequence in " .  A_ScriptDir . " ------------------------------")
	
    if LaunchNova()
    {
        
        Log("========= CheckFreeResources Start =========")
        if !CheckFreeResources()
        {
            Log ("ERROR : Failed to collect free resources !", 2)
            Goto TheEnd
        }
        Log("========= CheckFreeResources End   =========")
	
		Log("========= getFreeMecas Start =========")
		if !GetAvailableMecaCount(NumFreeMecas)
        {
            Log ("ERROR : Failed to get available mecas count !", 2)
            Goto TheEnd
        }
		Log("We have " . NumFreeMecas . " mecas left")
		
		Log("========= getFreeMecas End =========")
    
		Log("========= BuildFrigates Start =========")
        if !BuildFrigates(FrigatesAmount)
        {
            Log ("ERROR : Failed to build frigates !", 2)
            Goto TheEnd
        }
        Log("========= BuildFrigates End   =========")
		
        Log("========= CollectResources Start =========")
		if !CollectResources()
		{
			Log ("ERROR : Failed to collect resources !", 2)
			Goto TheEnd
		}
		  
        Log("========= CollectResources End   =========")
              
        
        Log("========= FarmPirate Start =========")
        if !FarmPirate()
        {
            Log ("ERROR : Failed to farm pirates !", 2)
            Goto TheEnd
        }
        Log("========= FarmPirate End   =========")
        
        ; logs the summuary of the iteration
        LogSummuary(1)
        
    }
    
    TheEnd:
    StopNova()
    Log("------------------------------ Stopping Sequence ------------------------------")
}

;*******************************************************************************
; LogSummuary : Logs the summuary
;*******************************************************************************
LogSummuary(Level :=0)
{
    global FreeResCollected, OtherResCollected, FrigatesBuilt, FrigatesAmount

    Log("SUMMUARY :", Level)
    Log(" -Free resources collected    : " . FreeResCollected, Level)
    Log(" -Regular resources collected : " . OtherResCollected, Level)
    Log(" -Frigates built              : " . FrigatesBuilt . " / " . FrigatesAmount, Level)    
}

;*******************************************************************************
; ReadConfig : Reads the configuration file
;*******************************************************************************
ReadConfig()
{
    global FreeResCollected, OtherResCollected, FrigatesBuilt, FrigatesAmount, LoopTime 
    FullPath =  %A_ScriptDir%\Nova.ini
    
    ; Counters
    IniRead, FreeResCollected, %FullPath%, COUNTERS, FreeResCollected, 0
    IniRead, OtherResCollected, %FullPath%, COUNTERS, OtherResCollected , 0
    IniRead, FrigatesBuilt, %FullPath%, COUNTERS, FrigatesBuilt, 0
    
    IniRead, FrigatesAmount, %FullPath%, PARAMETERS, FrigatesAmount, 0
    IniRead, LoopTime, %FullPath%, PARAMETERS, LoopTime, 300000
    
}

;*******************************************************************************
; WriteConfig : Writes the configuration file
;*******************************************************************************
WriteConfig()
{
    global FreeResCollected, OtherResCollected, FrigatesBuilt, FrigatesAmount, LoopTime 
    FullPath =  %A_ScriptDir%\Nova.ini
    
    ; Counters
    IniWrite, %FreeResCollected%, %FullPath%, COUNTERS, FreeResCollected
    IniWrite, %OtherResCollected%, %FullPath%, COUNTERS, OtherResCollected
    IniWrite, %FrigatesBuilt%, %FullPath%, COUNTERS, FrigatesBuilt
    
    IniWrite, %FrigatesAmount%, %FullPath%, PARAMETERS, FrigatesAmount
    IniWrite, %LoopTime%, %FullPath%, PARAMETERS, LoopTime
}

;*******************************************************************************
; LaunchNova : Will Launch nova, that is strt it by clikcing on Bluestacks
; icon and all the necessary clicks until main screen is on 
;*******************************************************************************
LaunchNova()
{
    global AppX, AppY, AppW, AppH
    global MainWinX, MainWinY, MainWinW, MainWinH
    global BlueStacksPath
	
	SetTitleMatchMode 2
	SetControlDelay 1
	SetWinDelay 0
	SetKeyDelay -1
	SetBatchLines -1

    if (!WinExist("BlueStacks"))
    {
        Log("***** Launching BlueStacks...")
        Run, %BlueStacksPath%
        sleep, 1000
        WinWait, BlueStacks,, 100
    
        Log("Waiting for BlueStacks to be fully started...")
    }
    else
    {
        Log("BlueStacks is launched")
    }
    
    ; Activate BlueStacks Window
    WinActivate, BlueStacks
    WinMove, BlueStacks,, AppX, AppY, AppW, AppH
    WinGetPos, MainWinX, MainWinY, MainWinW, MainWinH, BlueStacks
   
    ; click home tab
    Log("Waiting for BlueStacks home tab ...")
    if !NovaFindClick("buttons\bs_home.png", 0, "w60000 n1")
    {
        Log("ERROR : Failed to select home screen, exiting...", 2)
        return 0
    }
    
    ; click nova app
	
    Log("Waiting for BlueStacks Nova icon ...")
    if !NovaFindClick("buttons\nova_icon_big.png", 0, "w60000 n0")
    {
        Log("ERROR : Failed to find nova app icon, exiting...", 2)
        return 0
    }
	
	sleep, 1000
    if !NovaFindClick("buttons\nova_icon_big.png", 0, "w1000 n1")
    {
        Log("ERROR : Failed to start nova app icon, exiting...", 2)
        return 0
    }

    
    ; click nova tab
    Log("***** Launching Nova Empire...")
    Log("Waiting for BlueStacks Nova tab ...")
    if !NovaFindClick("buttons\nova_icon.png", 20, "w5000 n1")
    {
        Log("ERROR : Failed to find nova tab, exiting...", 2)
        return 0
    }
    
    ; check CEG button
    Log("Waiting for Nova Main screen ...")
    if !NovaFindClick("buttons\ceg.png", 30, "w1000 n0", FoundX, FoundY, 1500, 40, 1760, 150)
    {
        ; we dont have CEG, we might have the start avatar
        Log("Waiting for Nova welcome screen ...")
        if !NovaFindClick("buttons\cross.png", 0, " w60000 n1")
        {
            Log("ERROR : Could not identify properly the start screen, exiting...", 2)
            return 0
        }
    }
    
    Log("***** Nova is up and running.")
    return 1
}

;*******************************************************************************
; StopNova : Will Stop nova by closing it in blue stacks
;*******************************************************************************
StopNova()
{
    
    ; Now Close BlueStacks
    Log("Closing BlueStacks...")
    WinClose, BlueStacks
    sleep, 2000
    
    ; Click on the confirm button
    if !NovaFindClick("buttons\yes.png", 0, "w1000 n1")
    {
        Log("ERROR : Could not find exit confirm button, exiting...", 2)
    }
    
    ; Wait for it to close
    Log("Waiting for BlueStacks to close...")    
    while WinExist("BlueStacks")
    {
        sleep, 1000
    }
    
    Log("BlueStacks is closed.")
}