#include utils.ahk

;*******************************************************************************
; HandleResource : Handle the collection of a single ressource
; X, Y : Window coordinate of the location of the resource
;*******************************************************************************
HandleResource(X, Y)
{
	Log("Found a resource at (" . X . "," . Y . "), identifying ...")
	
	; Click it
	NovaLeftMouseClick(X, Y)
	Sleep, 500
	
	; Identify it
	ResType := IdentifyRessource
	
	if (ResType = "UNKNOWN")
	{
		Log("ERROR : failed to indentify resources, exiting.")
		return 0
	}
	
	Log("Found a ressource of type " . ResType)
	
	
	return 1
}

;*******************************************************************************
; IdentifyRessource : Will identify a ressource type clicked on screen
; Will return "MINERALS", "CRYSTALS", "ALLIUM" or "UNKNOWN"
;*******************************************************************************
IdentifyRessource()
{
    global
	if NovaFindClick("resources\Type_Mineraux.png", 50, "w1000 n0")
	{
		return "MINERALS"
	}
	
	if NovaFindClick("resources\Type_Cristaux.png", 50, "w1000 n0")
	{
		return "CRYSTALS"
	}
	
	if NovaFindClick("resources\Type_Allium.png", 50, "w1000 n0")
	{
		return "ALLIUM"
	}
	
	return "UNKNOWN"
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
        Log("ERROR : Failed to toggle 2D mode, exiting.")
        return 0
    }
    
    ; Zoom out to get the whole map on screen
    ; control  mousewheel
    Log("Zooming out the map ...")
    WinActivate, BlueStacks
    WinMove, BlueStacks,, AppX, AppY, AppW, AppH
    WinGetPos, MainWinX, MainWinY, MainWinW, MainWinH, BlueStacks
    NovaMouseMove(MainWinW/2, MainWinH/2)
    Send, {Control down}
    MouseClick, WheelDown,,, 1
    Sleep, 2000
    Send, {Control up}
    
    ; now Look for all resources on the map and call our callback
    Log("Looking for resources ...")
    ResCount := NovaFindClick("resources\res1.png", 20, "e n0 w1000 FuncHandleResource")
	Log("We found " . ResCount . " resources.")
    Log("End of resources collection.")
	
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
    if !NovaFindClick("buttons\right_menu_off.png", 80, "w1000 n0")
    {
        Log("Unfolding 2D/3D menu")
        if !NovaFindClick("buttons\right_menu_on.png", 80, "w1000 n1")
        {
            Log("ERROR : Failed to unfold thr right 2D/3D menu, stopping")
            return 0
        }
    }
    else
    {
        Log("2D/3D panel already out")
    }

    ; switch to 2D
    if NovaFindClick("buttons\2D.png", 20, "w1000 n0")
    {
        Log("Switching to 2D")
        if !NovaFindClick("buttons\3D_dot.png", 20, "w1000 n1")
        {
            Log("ERROR : Failed to find the 3D dot to click, stopping")
            return 0
        }
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
