#include utils.ahk

MapPosX := 0
MapPosY := 0

; scan area coordinates
AreaX1 := 300
AreaY1 := 170
AreaX2 := 1600
AreaY2 := 980

; Current type of ressoures
CurrentResType := ""
RemainingMecas := 0

;*******************************************************************************
; HandleResource : Handle the collection of a single ressource
; X, Y : Window coordinate of the location of the resource
;*******************************************************************************
HandleResource(X, Y)
{
	global
	X := X - MainWinX
	Y := Y - MainWinY
	
	; exit if we have no more mecas
	if (RemainingMecas = 0)
		Return
		
	Log("Found a resource at (" . X . "," . Y . "), with type " . CurrentResType)
	
	; Click the resource
	NovaLeftMouseClick(X, Y)
	Sleep, 500
	
	; click collect button
	Log("Collecting it ...")
	if !NovaFindClick("buttons\collect.png", 70, "w2000 n1")
	{
		Log("ERROR : failed to find collect button, exiting.")
		return
	}
	
	; eventually click on the OK button if we had no more mecas
	if NovaFindClick("buttons\Ok.png", 50, "w2000 n1")
	{
		Log("Obviosuly no more mecas ...")
		RemainingMecas := 0
		return
	}
	Else
	{
		Log("sending meca ...")
		OtherResCollected := OtherResCollected + 1
	}
	
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

	RemainingMecas := 1
	
	CollectResourcesByType("ALLIUM")
	
	if (RemainingMecas)
		CollectResourcesByType("CRYSTALS")
	
	if (RemainingMecas)
		CollectResourcesByType("MINERALS")
	
    Log("End of resources collection.")
	
    return 1
}


;*******************************************************************************
; CollectResourcesByType : browse the map and collect a ressource from The
; given type
;*******************************************************************************
CollectResourcesByType(ResType)
{

	global
	; Loop the map to scan ressources
	X := -2
	Y := 3
	Dir := 1
	TotalRes := 0
	
	Log("Looking for resources " . ResType . "...")
	
	; Loop Y
	Loop, 7
	{
		; Loop X
		Loop, 5 
		{
			MapMoveTo(X,Y)
			
			TotalRes := ScanArea(ResType)
			
			; exit if we have no more mecas
			if (RemainingMecas = 0)
				Goto CollectEnd
				
			X := X + Dir
		}
		
		X := X - Dir 
		Dir := -Dir
		Y := Y - 1
	}
	
CollectEnd:
	MapMoveTo(0,0)
	
    ; now Look for all resources on the map and call our callback
	Log("We found " . TotalRes . " resources for " . ResType)
}


;*******************************************************************************
; ScanArea : Scan current map area for Restype ressource
; Will return the number of ressources found and update teh ressources 
; global info
;*******************************************************************************
ScanArea(ResType)
{
	global
	CurrentResType := ResType
	
	If (ResType = "ALLIUM")
	{
		return NovaFindClick("resources\HD_Allium2.png", 50, "e n0 FuncHandleResource", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	}
		
	If (ResType = "CRYSTALS")
	{
		return NovaFindClick("resources\HD_Crystals2.png", 50, "e n0 FuncHandleResource", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	}
	
	If (ResType = "MINERALS")
	{
		CountMine :=  NovaFindClick("resources\HD_Mine2.png", 50, "e n0 FuncHandleResource", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		
		CountPlanet :=  NovaFindClick("resources\HD_Planet2.png", 80, "e n0 FuncHandleResource", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		
		return (CountMine + CountPlanet)
	}

	return 0
}


;*******************************************************************************
; Toggle2DMode : Toggles the 2D mode on the system screen
;*******************************************************************************
Toggle2DMode()
{
    global
    Log("Toggling 2D Mode ...")
    
    ; Look if pane is already openned
    if !NovaFindClick("buttons\right_menu_off.png", 80, "w1000 n0", FoundX, FoundY, 1450, 640, 1760, 820)
    {
        Log("Unfolding 2D/3D menu")
        if !NovaFindClick("buttons\right_menu_on.png", 80, "w1000 n1", FoundX, FoundY, 1450, 640, 1760, 820)
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
    if NovaFindClick("buttons\2D.png", 20, "w1000 n0", FoundX, FoundY, 1450, 640, 1760, 820)
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
	StepX := 1100
    StepY := 600
	MoveX := 0
	MoveY := 0
	MoveXDir := 0
	MoveYDir := 0
	
	if (X > MapPosX)
	{
        MoveX := X - MapPosX
		MoveXDir := -1
	}
	else if (X < MapPosX)
	{
        MoveX := MapPosX - X
		MoveXDir := 1
	}
	
	if (Y > MapPosY)
	{
		MoveY := Y - MapPosY
		MoveYDir := 1
	}
	else if (Y < MapPosY)
	{
		MoveY := MapPosY - Y
		MoveYDir := -1
	}
	
	; now we need to move 
	if (MoveX > MoveY)
		LoopCount := MoveX
	Else	
		LoopCount := MoveY
	
	Loop, %LoopCount%
	{
		NovaDragMouse(MainWinW /2, MainWinH /2, MoveXDir * StepX, MoveYDir * StepY)
		MoveX := MoveX - 1
		MoveY := MoveY - 1
		
		if MoveX <= 0 
			MoveXDir := 0
			
		if MoveY <= 0 
			MoveYDir := 0
	}
		
	MapPosX := X
	MapPosY := Y
}
