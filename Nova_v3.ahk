; This script was created using Pulover's Macro Creator
; www.macrocreator.com


#Include  %A_ScriptDir% 
#include libs\FindClick.ahk
#Include utils.ahk
#include screens.ahk


#NoEnv
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
;SendMode Event
#SingleInstance Force
SetTitleMatchMode 2
#WinActivateForce
SetControlDelay 1
SetWinDelay 0
SetKeyDelay -1
;SetMouseDelay -1
SetBatchLines -1

; Working directory
BlueStacksPath := "C:\ProgramData\BlueStacks\Client\Bluestacks.exe"

; Loop time and activation
LoopTime := 5 * 60000
DoLoop := 1
    
; Window Size
AppW := 1280
AppH := 720

; Window Position
AppX := 139
AppY := 80

; free resources collected
FreeResCollected := 0

; regular free collected
OtherResCollected := 0

; Frigates amount to build
FrigatesAmount := 700
FrigatesBuilt := 0

Log("Nova Empire Automation - (c) LongChair 2019")
  
Loop
{
    
    
    
    /*
    LaunchNova()
	r := NovaFindClick("buttons\nova_icon_big.png", 30 , "n0", FoundX, FoundY)
    
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
    
    /*
    SendDiscord("Blah blah test")
    Sleep, 60000
    */
    
    
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
        
        Loop, 10000
        {
            MyScreen := GetNovaScreen()
            Log("Screen " . MyScreen )
            Sleep, 1000
        } 
 
        ;~ Log("========= CheckFreeResources Start =========")
        ;~ if !CheckFreeResources()
        ;~ {
            ;~ Log ("ERROR : Failed to collect free resources !")
            ;~ Goto TheEnd
        ;~ }
        ;~ Log("========= CheckFreeResources End   =========")
        
        ;~ Log("========= CollectResources Start =========")
        ;~ if !CollectResources()
        ;~ {
            ;~ Log ("ERROR : Failed to collect resources !")
            ;~ Goto TheEnd
        ;~ }
        ;~ Log("========= CollectResources End   =========")
        
        
        ;~ Log("========= BuildFrigates Start =========")
        ;~ if !BuildFrigates(FrigatesAmount)
        ;~ {
            ;~ Log ("ERROR : Failed to build frigates !")
            ;~ Goto TheEnd
        ;~ }
        ;~ Log("========= BuildFrigates End   =========")
        
        ;~ Log("========= FarmPirate Start =========")
        ;~ if !FarmPirate()
        ;~ {
            ;~ Log ("ERROR : Failed to farm pirates !")
            ;~ Goto TheEnd
        ;~ }
        ;~ Log("========= FarmPirate End   =========")
        
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
    
}

;*******************************************************************************
; CheckFreeResources : Checks and grabs free ressources
;*******************************************************************************
CheckFreeResources()
{   
    global
    ; Go into space station screen 
    Log("Checking free resources ...")
    if !GotoScreen("STATION", 60)
    {
        return 0
    }
	
    ; Loof if we have day start icon
    if (FindImage("buttons\day_1.png", 133, 551, 408, 676, FoundX, FoundY, 80))
    {
        Log("Validating Day 1!")
        MajorLog("Validating Day 1!")
        
        ; Click on the free resources button
        NovaLeftMouseClick(FoundX + 20, FoundY + 20)
        
        
        ; click on the collect button
        if !WaitImage("buttons\recuperer.png", 421, 482, 704, 579, 10, FoundX, FoundY, 80)
        {
            Log("ERROR : Timeout waiting for the collect button, stopping")
            return 0
            
        }
        
        Log("Validating daily collect ...")
        NovaLeftMouseClick(FoundX + 20, FoundY + 20)
        sleep, 1000
        
        ; reset free resources counter
        FreeResCollected := 0
        
        ; click on the return button
        Log("clicking on return button")
        NovaLeftMouseClick(98, 78)
        sleep, 1000
        
        Log("Waiting to return to station screen ...")
        if !WaitNovaScreen("STATION", 10)
        {
            return 0
        }
    }
    
	; Look if we have the free ressources icon
	if (FindImage("free_ressources.png", 267, 579, 329, 651, FoundX, FoundY, 0))
	{
		Log("Collecting resources ... YEAH!")
        MajorLog("Collecting resources ... YEAH!")
        
        ; Click on the free resources button
        NovaLeftMouseClick(FoundX + 20, FoundY + 20)
        Sleep, 1000
        
        ; Grab a screenshot of the resource
        NovaGrab(443, 244, 250, 230)
        Sleep, 1000
        
       ; click on the collect button
        if !WaitImage("buttons\recuperer.png", 421, 482, 704, 579, 10, FoundX, FoundY, 80)
        {
            Log("ERROR : Timeout waiting for the collect button, stopping")
            return 0
            
        }
        
        Log("Validating resouce collection ...")
        NovaLeftMouseClick(FoundX + 20, FoundY + 20)
        FreeResCollected := FreeResCollected + 1 
        sleep, 2000
        
        
        ; click below the popup to make it vanish
        Log("Waiting for reward screen to get away ...")
        LoopCount := 0
        Loop
        {
            NovaLeftMouseClick(452, 635)
            LoopCount := LoopCount + 1
        } Until WaitNovaScreen("STATION", 1) or LoopCount > 5
        
        if LoopCount > 5 
        {
            Log("ERROR : Timeout waiting for station screen, stopping")
            return 0
        }
	}
	Else
    {
        Log("No free resources :/")
    }
    
    return 1
}

;*******************************************************************************
; Toggle2DMode : Toggles the 2D mode on the system screen
;*******************************************************************************
Toggle2DMode()
{
    global
    Log("Toggling 2D Mode ...")
    
    
    ; Look if pane is already openned
    if (not FindImage("buttons\3D_dot.png", 940, 414, 1121, 519, FoundX, FoundY))
    {
        Log("Unfolding 2D/3D menu")
        ; Click on the right button to pop 2D/3D out
        NovaLeftMouseClick(1110, 473)
        Sleep, 1000
    }
    else
    {
        Log("2D/3D panel already out")
    }

    ; Now Pane is popped out, make sure we are in 2D mode
    if (FindImage("buttons\2D.png", 972, 428, 1049, 470, FoundX, FoundY, 50))
    {
        Log("Switching to 2D")
        ; Click on the 2D button
        NovaLeftMouseClick(1014, 478)
        Sleep, 1000
    }
    else
    {
        Log("Already in 2D")
    }

    ; wait eventually for system screen
    if !WaitNovaScreen("SYSTEME", 10)
    {
        return 0
    }
    
    return 1
}

;*******************************************************************************
; CheckandPick : Check if there are ressources and pick them
;*******************************************************************************
CheckandPick()
{
    global
    ResType := ""
    Found := false
    
    ; check first mineral type
    if (not Found)
    {
        Found := FindImage("resources\minerai_2d.png", 131, 186, 951, 556, FoundX, FoundY, 30)
        if (Found)
        {
            ResType := "Mineral #1"
        }
    }
    
    ; check another mineral type
    if (not Found)
    {
        Found := FindImage("resources\minerai_2d_full.png", 131, 186, 951, 556, FoundX, FoundY, 60)
        if (Found)
        {
            ResType := "Mineral #2"
        }
    }
    
    ; check crystal type
    if (not Found)
    {
        Found := FindImage("resources\crystal_2d_full.png", 131, 186, 951, 556, FoundX, FoundY, 60)
        if (Found)
        {
            ResType := "Crystals"
        }
    }
    
    ; check planet type
    if (not Found)
    {
        Found := FindImage("resources\planet.png", 131, 186, 951, 556, FoundX, FoundY, 80)
        if (Found)
        {
            ResType := "Planet"
        }
    }
    
        
    if (Found)
    {
        Log("Found " . ResType . " at (" . FoundX . "," . FoundY . ")")
        ; found a ressource, click on it
        NovaLeftMouseClick(FoundX + 20, FoundY + 20)
        Sleep, 2000
        
        if !WaitImage("buttons\collect.png",  710, 159, 792, 245, 3, FoundX, FoundY, 30)
        {
            Log("ERROR : Could not find the collect button, exiting.")
            return 0
        }
        
        ; click on collect button
        NovaLeftMouseClick(FoundX + 20, FoundY + 20)
        
        ; here we can eventually have no more meca, a popup with OK will show, 
        ; we look for it
        if WaitImage("buttons\OK.png", 458, 446, 677, 531, 3, FoundX, FoundY, 30)
        {
            Log("Obviously no more meca ...")
            
            ; click on OK button
            NovaLeftMouseClick(FoundX + 20, FoundY + 20)
            sleep, 1000
            
            ; eventually here, previous click will raise a 
            ; contextual menu, that will hide all the screen identification
            ; markers, so we can click again to dismiss it
            While (GetNovaScreen() = "UNKNOWN")  
            {
                Log("Screen was unknown, clicking to try to escape menu")
                NovaLeftMouseClick(548, 603)
                sleep, 1000
            }
        }
        else
        {
            MajorLog("Sent Meca on " . ResType)
            ; we had a meca it seems
            OtherResCollected := OtherResCollected + 1
        }
        
        return 1
    }
    Else
    {
        ;Log("No resource found :/")
        return 0
    }
}

;*******************************************************************************
; CollectResources : Parse current system and collect ressources if any
; by sending workers onto them
;*******************************************************************************
CollectResources()
{
    global
    Log("Starting to collect resources ...")
    
    ; we need the system screen
    if !GotoScreen("SYSTEME", 60)
    {
        return 0
    }
    
    ; then go in 2D Mode
    if !Toggle2DMode()
    {
        return 0
    }
    
    ; Now look for resources
    ; Put Mouse coursor at window center
    NovaMouseMove(MainWinW / 2 , MainWinH / 2)
    Sleep, 10
    
    Step := 350
    HSteps := 4
    VSteps := 10
    

    LoopY := VSteps / 2 
    ; go down the screen
    Log("Going down the map ...")
    Loop, %LoopY%
    {
        MouseClick, WheelDown,,, 1
        Sleep, 1000
    }
    
    ; Go to right of screen
    Log("Going left the map ...")
    LoopX := HSteps / 2 
    Loop, %LoopX%
    {
        NovaDragMouse(MainWinW /2, MainWinH /2, Step, 0)
    }
        
    ; now we will browse upwards, 
    LoopY := VSteps 
    Loop, %VSteps%
    {
        ; reverse direction
        Step :=  -Step
        
        ; now browse up to left
        Loop, %HSteps%
        {
            NovaDragMouse(MainWinW /2, MainWinH /2, Step, 0)
            if CheckAndPick()
            {
                Log("Exiting resources collection.")
                return 1
            }
        }

        ; Go up one wheel move
        MouseClick, WheelUp,,, 1
        Sleep, 1000
    }

    return 1
}

;*******************************************************************************
; PopRightMenu : Will pop the main right menu
; Visible : 1 = Show it, 0 = Close it
;*******************************************************************************
PopRightMenu(Visible)
{
    global
    
    
    if (Visible)
    {
        Log("Showing Main right menu ...")
        ; click the button to show up the menu
        NovaLeftMouseClick(1083, 339)
        Sleep, 500
        
        ; wait for eventual unselected economy tab
        if WaitImage("buttons\economy_off.png",  921, 70, 1116, 215, 1, FoundX, FoundY, 30)
        {
            ; click on it to select economy
            NovaLeftMouseClick(FoundX + 20 , FoundY + 20)
        }
        
        ; wait for economy on button
        if !WaitImage("buttons\economy_on.png",  921, 70, 1116, 215, 10, FoundX, FoundY, 30)
        {
            Log("Couldn't Find the economy button, exiting.")
            return 0
        }
        
        ; we found button, that's done
        return 1
        
    }
    else
    {
        Log("Hiding Main right menu ...")
        
        ; click on avatar zone to get the menu away
        NovaLeftMouseClick(69, 56)
        
        ; make sure we don't have the menu bar again
        if !WaitNoImage("buttons\menu_bar.png",  449, 78, 977, 106, 10, 30)
        {
            Log("ERROR : Timeout for menu bar to disappear, exceeded 10 seconds.")
            return 0
        }
        
        return 1
    }
}

;*******************************************************************************
; BuildFrigates : Will try to queue frigates until the amount is reached
; Amount : Number of frigates that should be built
;*******************************************************************************
BuildFrigates(Amount)
{
    global
    if (Amount <= FrigatesBuilt)
    {
        Log("We already have built " . FrigatesBuilt . ", skipping for now.")
        return 1
    }
    
    ; popup the main menu
    if !PopRightMenu(1)
    {
        Log("ERROR : failed to popup main menu. exiting")
        return 0
    }
    
    ;Look for a free slot
    Search := 1
    DownCount := 0
    while Search and DownCount <= 2
    {
        Log("Looking for a free shipyard slot...")
        if WaitImage("buttons\free_slot.png", 540, 100, 976, 752, 2, FoundX, FoundY, 70)
        {
            Log("Found a free shipyard slot, clicking on it...")
            ; click on free slot
            NovaLeftMouseClick(FoundX + 20, FoundY + 20)
            
            ; make sure frigates are selected on that shipyard
            if !WaitImage("buttons\frigate.png",  6, 279, 201, 400, 2, FoundX, FoundY, 0)
            {
                Log("Could not find frigates as current ship, exiting.")
                return 0
            }
            
            ; then click on build button
            if !WaitImage("buttons\build.png", 951, 457, 1106, 520, 2, FoundX, FoundY, 0)
            {
                Log("Could not find build button, exiting.")
                return 0
            }
            
            ; click on build button
            Log("Clicking on shipyard slot...")
            NovaLeftMouseClick(FoundX + 20, FoundY + 20)
            sleep,1000
            
            FrigatesBuilt := FrigatesBuilt + 1
            
            ; then click on back button                
            if !WaitImage("buttons\back.png", 2, 48, 142, 103, 2, FoundX, FoundY, 0)
            {
                Log("Could not find back button, exiting.")
                return 0
            }
            
            Log("Clicking on back button...")
             ; click on back button
            NovaLeftMouseClick(FoundX + 20, FoundY + 20)
            
            ; wait for right menu to come back
            Log("Wait for right menu to come back...")
            if !WaitImage("buttons\economy_on.png",  921, 70, 1116, 215, 5, FoundX, FoundY, 30)
            {
                Log("Couldn't Find the economy button, exiting.")
                return 0
            }

        }
        else
        {
            Log("No more free slots found, scrolling down...")
            
            ; Scroll up to find eventual new shipyards slots
            DownCount := DownCount + 1
            
            ; move mouse on top of shipyards
            NovaMouseMove(680, 305)
            sleep, 500
            
            MouseClick, WheelDown,,, 1
            Sleep, 3000
        }
    }
    
    ; Discard the main menu
    if !PopRightMenu(0)
    {
        Log("ERROR : failed to discard main menu. exiting")
        return 0
    }
    
    return 1
}

;*******************************************************************************
; FarmPirate : Will try to find a pirate, kill it and collect resource
;*******************************************************************************
FarmPirate()
{
    global
    Log("Not Yet Implemented")
    return 1
}

;*******************************************************************************
; LaunchNova : Will Launch nova, that is strt it by clikcing on Bluestacks
; icon and all the necessary clicks until main screen is on 
;*******************************************************************************
LaunchNova()
{
    global
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
    if !NovaFindClick("buttons\nova_icon.png", 0, "w1000 n1")
    {
        Log("ERROR : Failed to find nova tab, exiting...")
        return 0
    }
    
    ; check CEG button
    Log("Waiting for Nova Main screen ...")
    if !NovaFindClick("buttons\ceg.png", 30, "w1000 n0")
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


;*******************************************************************************
; IdentifyRessource : Will identify a ressource type clicked on screen
; Will return "MINERALS", "CRYSTALS", "ALLIUM" or "UNKNOWN"
;*******************************************************************************
IdentifyRessource()
{
    global
	if (FindImage("resources\Type_Mineraux.png", 354, 311, 480, 351, FoundX, FoundY, 50))
	{
		return "MINERALS"
	}
	
	if (FindImage("resources\Type_Cristaux.png", 354, 311, 480, 351, FoundX, FoundY, 50))
	{
		return "CRYSTALS"
	}
	
	if (FindImage("resources\Type_Allium.png", 354, 311, 480, 351, FoundX, FoundY, 50))
	{
		return "ALLIUM"
	}
	
	return "UNKNOWN"
}

;*******************************************************************************
; MapMoveTo : Move to a position on the map, using mouse scrolls
; Will return maintain MapPosX and MapPosY
;*******************************************************************************
MapMoveTo(X, Y)
{
    global
	Log("Moving on map to " . X . ", " . Y)
	StepX := 200
    StepY := 100
	if (X > MapPosX)
	{
        LoopCount := X - MapPosX
		Loop, %LoopCount%
		{
			NovaDragMouse(MainWinW /2, MainWinH /2, -StepX, 0)
		}
	}
	else if (X < MapPosX)
	{
        LoopCount := MapPosX - X
		Loop, %LoopCount%
		{
			NovaDragMouse(MainWinW /2, MainWinH /2, StepX, 0)
		}
	}
	
	if (Y > MapPosY)
	{
        LoopCount := Y - MapPosY
		Loop, %LoopCount%
		{
			NovaDragMouse(MainWinW /2, MainWinH /2, 0, StepY)
		}
	}
	else if (Y < MapPosY)
	{
        LoopCount := MapPosY - Y
		Loop, %LoopCount%
		{
			NovaDragMouse(MainWinW /2, MainWinH /2, 0, -StepY)
		}
	}
	
	MapPosX := X
	MapPosY := Y
}
