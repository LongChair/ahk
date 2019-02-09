; Nova automation  LongChair 2019
; This script automates a few non fun tasks in Nova empire

#Include  %A_ScriptDir% 
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

; script version
Version := "3.0"

; Working directory
BlueStacksPath := "C:\ProgramData\BlueStacks\Client\Bluestacks.exe"

; Loop time and activation
LoopTime := 0
DoLoop := 1
    
; Window Size
AppW := 1920
AppH := 1080

; Window Position
AppX := 0
AppY := 0

; free resources collected
FreeResCollected := 0

; regular free collected
OtherResCollected := 0

; Frigates amount to build
FrigatesAmount := 0
FrigatesBuilt := 0


Log("Nova Empire Automation version " . Version . " - (c) LongChair 2019")


	
Loop
{
    
	
    ;LaunchNova()
	;WinActivate, BlueStacks
    ;WinMove, BlueStacks,, AppX, AppY, AppW, AppH
    ;WinGetPos, MainWinX, MainWinY, MainWinW, MainWinH, BlueStacks
	;
	;C := NovaFindClick("buttons\collect.png", 50, "w2000 n1")
	
	;C := ScanArea("MINERALS")
	;CountMine := NovaFindClick("resources\HD_Planet2.png", 80, "e n0 FuncHandleResource", FoundX, FoundY, 300, 170, 1600, 980)
    /*
    Loop
    {
        ;if (FindImage("pirates\pirate.png",  131, 186, 951, 556,  FoundX, FoundY, 100))
        ;if (FindImage("pirates\resource.png",  131, 186, 951, 556,  FoundX, FoundY, 30))
        if FindImage("buttons\free_slot.png", 540, 100, 976, 702, FoundX, FoundY, 70)
        {   
            Log("Image Found !")
            NovaMouseMove(FoundX + 20,FoundY +20 )
        }
        else
        {
            Log("Image NOT Found !")
        }
         Sleep, 3000
    }
    */
	
	
    ; Read Configureation
    Log("Reading Configuration...")
    ReadConfig()

    DoSequence()
     
    ; Write Configuration
    Log("Writing Configuration...")
    WriteConfig()
    
    Log("Waiting...")
    Sleep, LoopTime
    
} Until (not DoLoop)

;*******************************************************************************
; DoSequence : Main loop of the program
;*******************************************************************************
DoSequence()
{
    global
    Log("------------------------------Starting Sequence in " .  A_ScriptDir . " ------------------------------")
	
    if LaunchNova()
    {
        
        Log("========= CheckFreeResources Start =========")
        if !CheckFreeResources()
        {
            Log ("ERROR : Failed to collect free resources !")
            Goto TheEnd
        }
        Log("========= CheckFreeResources End   =========")
        
        Log("========= CollectResources Start =========")
        if !CollectResources()
        {
            Log ("ERROR : Failed to collect resources !")
            Goto TheEnd
        }
        Log("========= CollectResources End   =========")
        ;
        ;
        ;Log("========= BuildFrigates Start =========")
        ;if !BuildFrigates(FrigatesAmount)
        ;{
            ;Log ("ERROR : Failed to build frigates !")
            ;Goto TheEnd
        ;}
        ;Log("========= BuildFrigates End   =========")
        ;
        ;Log("========= FarmPirate Start =========")
        ;if !FarmPirate()
        ;{
            ;Log ("ERROR : Failed to farm pirates !")
            ;Goto TheEnd
        ;}
        ;Log("========= FarmPirate End   =========")
        
        Log("SUMMUARY :")
        Log(" -Free resources collected    : " . FreeResCollected)
        Log(" -Regular resources collected : " . OtherResCollected)
        Log(" -Frigates built              : " . FrigatesBuilt . " / " . FrigatesAmount)
    }
    
    TheEnd:
    StopNova()
    Log("------------------------------ Stopping Sequence ------------------------------")
}

;*******************************************************************************
; ReadConfig : Reads the configuration file
;*******************************************************************************
ReadConfig()
{
    global
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
    global
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
    global
	
	
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
        Log("ERROR : Failed to select home screen, exiting...")
        return 0
    }
    
    ; click nova app
    Log("Waiting for BlueStacks Nova icon ...")
    if !NovaFindClick("buttons\nova_icon_big.png", 0, "w60000 n1")
    {
        Log("ERROR : Failed to launch nova, exiting...")
        return 0
    }
    
    ; click nova tab
    Log("***** Launching Nova Empire...")
    Log("Waiting for BlueStacks Nova tab ...")
    if !NovaFindClick("buttons\nova_icon.png", 0, "w5000 n1")
    {
        Log("ERROR : Failed to find nova tab, exiting...")
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
            Log("ERROR : Could not identify properly the start screen, exiting...")
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
    global
    
    ; Now Close BlueStacks
    Log("Closing BlueStacks...")
    WinClose, BlueStacks
    sleep, 2000
    
    ; Click on the confirm button
    if !NovaFindClick("buttons\yes.png", 0, "w1000 n1")
    {
        Log("ERROR : Could not find exit confirm button, exiting...")
    }
    
    ; Wait for it to close
    Log("Waiting for BlueStacks to close...")    
    while WinExist("BlueStacks")
    {
        sleep, 1000
    }
    
    Log("BlueStacks is closed.")
}