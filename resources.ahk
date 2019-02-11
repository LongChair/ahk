#include globals.ahk
#include utils.ahk

; Current pistion in pixels on the map
global MapPosX := 0
global MapPosY := 0

; scan area coordinates
global AreaX1 := 300
global AreaY1 := 170
global AreaX2 := 1600
global AreaY2 := 980

; Current type of ressoures
global CurrentResType := ""
global RemainingMecas := 0

; different located ressources lists
global Ressources := []
global Mining := []


;*******************************************************************************
; GetAvailableMecaCount : Checks how many free mecas we have
;*******************************************************************************
GetAvailableMecaCount(ByRef NumMecas)
{
	AtWork := 0
	
	; popup the main menu
    if !PopRightMenu(1, "FLEETS")
    {
        Log("ERROR : failed to popup main menu for fleets. exiting", 2)
        return 0
    }
	
	; scroll down to mecas list
	Loop, 2
	{
		NovaMouseMove(1050, 470)
		MouseClick, WheelDown,,, 2
		Sleep 2000
	}
	
	; look how many mecas are at work
	AtWork := NovaFindClick("buttons\recuperation.png", 80, "e w1000 n0", FoundX, FoundY, 750, 220, 1340, 960)
	
	PopRightMenu(0)	
	
	NumMecas := 6 - AtWork
	
	return 1
}


;*******************************************************************************
; CountResByType : Returns the amount of scanned ressources with a given type
;*******************************************************************************
CountResByType(ResType)
{
	CurrentRes := 1
	Amount := 0
    
	Loop, % List.MaxIndex()
	{
		RefValues := StrSplit(List[CurrentRes], ",")
		if (RefValues[1] = ResType)
			Amount := Amount + 1
	}
	
	return Amount
}
	
;*******************************************************************************
; Toggle2DMode : Toggles the 2D mode on the system screen
;*******************************************************************************
Toggle2DMode()
{
    Log("Toggling 2D Mode ...")
    
    ; Look if pane is already openned
    if !NovaFindClick("buttons\right_menu_off.png", 80, "w1000 n0", FoundX, FoundY, 1450, 640, 1760, 820)
    {
        Log("Unfolding 2D/3D menu")
        if !NovaFindClick("buttons\right_menu_on.png", 80, "w1000 n1", FoundX, FoundY, 1450, 640, 1760, 820)
        {
            Log("ERROR : Failed to unfold thr right 2D/3D menu, stopping", 2)
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
        if !NovaFindClick("buttons\3D_dot.png", 20, "w5000 n1")
        {
            Log("ERROR : Failed to find the 3D dot to click, stopping", 2)
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
; MapMoveToXY : Move to a position on the map, using mouse scrolls
; Will return maintain MapPosX and MapPosY
;*******************************************************************************
MapMoveToXY(X, Y)
{
    global MapPosX, MapPosY
    global MainWinW, MainWinW
	
    StepX := 500
    StepY := 500
	MoveX := 0
    MoveY := 0
	MoveXDir := 0
    MoveYDir := 0
	
	Loop 
	{
		if (X >= MapPosX)
		{
			MoveX := X - MapPosX
			MoveXDir := -1
		}
		else if (X < MapPosX)
		{
			MoveX := MapPosX - X
			MoveXDir := 1
		}
		
		if (Y >= MapPosY)
		{
			MoveY := Y - MapPosY
			MoveYDir := 1
		}
		else if (Y < MapPosY)
		{
			MoveY := MapPosY - Y
			MoveYDir := -1
		}
		
		; cap move to Step
		if (MoveX > StepX)
			DragX := StepX * MoveXDir
		Else
			DragX := MoveX * MoveXDir

		if (MoveY > StepY)
			DragY := StepY * MoveYDir
		Else
			DragY := MoveY  * MoveYDir

		NovaDragMouse(MainWinW /2, MainWinH /2, DragX, DragY)
			
		MapPosX := MapPosX - DragX
		MapPosY := MapPosY + DragY
		
	} Until (MapPosX = X AND MapPosY = Y)
		
}

;*******************************************************************************
; CollectResourcesNew : Parse current system and collect ressources if any
; by sending workers onto them
;*******************************************************************************
CollectResources()
{
    global Ressources, Mining
    global NumFreeMecas
    
    Log("Starting to collect resources ...")
    
    ; we need the system screen
    if !GotoScreen("SYSTEME", 60)
    {
        return 0
    }
    
    ; then go in 2D Mode
    if !Toggle2DMode()
    {
        Log("ERROR : Failed to toggle 2D mode, exiting.", 2)
        return 0
    }

	Ressources := []
	Mining := []
		
	; Scan the map for ressources
	Log("Scanning map for ressources ...")
	ScanMap()
	
	; remove duplicate ressources
	Log("Sorting ressources ...")
	SortResList(Ressources)
	Log("We have " . Ressources.MaxIndex() . " ressources left after sorting")
	
	Log("Sorting mining mecas ...")
	SortResList(Mining)
	Log("We have " . Mining.MaxIndex() . " meca mining minerals left after sorting")


	AvailAllium := CountResByType("ALLIUM")
	AvailCrystals := CountResByType("CRYSTALS")
	MiningMecas := CountResByType("MINING")
	
	Log("Scan reported :")
	Log(" - Allium   : " . AvailAllium)
	Log(" - Crystals : " . AvailCrystals)
	
	; now try to grab the ressource
	if (NumFreeMecas = 0) 
	{
		if (MiningMecas AND (AvailAllium OR AvailCrystals))
			Log("We have " . MiningMecas . " mining mecas, and " . AvailAllium . " allium, " . AvailCrystals . " crystals, we could have swapped...")
	}
	Else
	{
		if CollectRessourcesByType("ALLIUM")
			if CollectRessourcesByType("CRYSTALS")
				CollectRessourcesByType("MINE")
	}
	
    Log("End of resources collection.")
	
    return 1
}


;*******************************************************************************
; CollectResourcesByType : browse the map and collect a ressource from The
; given type
;*******************************************************************************
ScanMap()
{
    global Ressources
	
    CurrentX := -1500
    CurrentY := 1500
	MapStepX := 1000
    MapStepY := 500
	Dir := 1
	
	; Scan the ressources on the map and fill the ressources array
	; Loop Y
	Loop, 7
	{
		; Loop X
		Loop, 4
		{
			MapMoveToXY(CurrentX, CurrentY)

			FindRessources()
		
			CurrentX := CurrentX + MapStepX
	
		}
		
		CurrentX := CurrentX - MapStepX
		MapStepX := -MapStepX
		CurrentY := CurrentY - MapStepY
	}
	
	Log("ScanMap found " . Ressources.MaxIndex() . " Ressources")
	
}

;*******************************************************************************
; ScanArea : Scan current map area for Restype ressource
; Will return the number of ressources found and update teh ressources 
; global info
;*******************************************************************************
FindRessources()
{
	global CurrentResType
    global AreaX1, AreaY1, AreaX2, AreaY2
    
	
	CurrentResType := "ALLIUM"
	NovaFindClick("resources\HD_Allium.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)	
	NovaFindClick("resources\HD_Planet_Allium.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	
	CurrentResType := "CRYSTALS"
	NovaFindClick("resources\HD_Crystals.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	NovaFindClick("resources\HD_Planet_Crystals.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	
	CurrentResType := "MINE"
	NovaFindClick("resources\HD_Mine.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	NovaFindClick("resources\HD_Planet2.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	
	CurrentResType := "MINING"
	;NovaFindClick("resources\HD_Mine2.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	NovaFindClick("resources\Planet_Mining.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	return 0
}

;*******************************************************************************
; HandleScan : Handle the collection of a single ressource
; ResX, ResY : Window coordinate of the location of the resource
;*******************************************************************************
HandleScan(ResX, ResY)
{
	global MainWinX, MainWinY
    global MainWinW, MainWinH
    global Ressources, Mining
    
	ResX := (ResX - MainWinX - (MainWinW / 2)) + MapPosX
	ResY := MapPosY - (ResY - MainWinY - (MainWinH / 2))

	if (CurrentResType = "MINING")
	{
		Mining.Insert(CurrentResType . "," . ResX . "," . ResY)
		Log("Found a mined resource at (" . ResX . "," . ResY . "), with type " . CurrentResType . " Total=" . Mining.MaxIndex())
	}
	else
	{
		Log("Found a resource at (" . ResX . "," . ResY . "), with type " . CurrentResType . " Total=" . Ressources.MaxIndex())
		Ressources.Insert(CurrentResType . "," . ResX . "," . ResY)
	}
}

;*******************************************************************************
; SortRessources : Removes the dupplicate ressources
; ResList : List of resources to sort
;*******************************************************************************
SortResList(Byref ResList)
{

SortStart:
	
	CurrentRes := 1
	Loop, % ResList.MaxIndex()
	{
		RefValues := StrSplit(ResList[CurrentRes], ",")
		
		CompareRes := CurrentRes + 1
		Loop, % ResList.MaxIndex() - CurrentRes
		{
			CompareValues := StrSplit(ResList[CompareRes], ",")
			
			if (Abs(CompareValues[2] - RefValues[2]) < 10) AND (Abs(CompareValues[3] - RefValues[3]) < 10)
			{
				Log("Removing dupplicate " . ResList[CompareRes] . " of " . ResList[CurrentRes])
				ResList.RemoveAt(CompareRes)
				Goto SortStart
			}
				
			CompareRes := CompareRes + 1 
		}
		CurrentRes := CurrentRes + 1
	}
}

;*******************************************************************************
; CollectRessourcesByType : Collect a given type of ressource
; ResType : type of resource , can be 3ALLIUM", "CRYSTALS" or "MINE"
;*******************************************************************************
CollectRessourcesByType(ResType)
{
	global NumFreeMecas, OtherResCollected
    global Ressources
    global MainWinW, MainWinH
	
	if (NumFreeMecas = 0)
	{
		Log("Looks like we have no more mecas, exiting")
		return 0
	}
		
		
	Log("Collecting ressources found for " . ResType)
	CurrentRes := 1
	Loop, % Ressources.MaxIndex()
	{
		RefValues := StrSplit(Ressources[CurrentRes], ",")
		ResX := RefValues[2]
		ResY := RefValues[3]

		; Check ressource Type
		if (RefValues[1] = ResType)
		{
			; go to the ressource position
			Log("Going to collect " . ResType . " at (" . ResX . "," . ResY . ") ...", 1)
			MapMoveToXY(ResX, ResY)

			
			; Click on the ressource
			NovaLeftMouseClick(MainWinW / 2, MainWinH / 2)
			
			; click collect button
			Log("Collecting it ...")
			if !NovaFindClick("buttons\collect.png", 70, "w2000 n1")
			{
				Log("ERROR : failed to find collect button, exiting.", 2)
				return 0
			}
			
			; eventually click on the OK button if we had no more mecas
			if NovaFindClick("buttons\Ok.png", 50, "w2000 n1")
			{
				Log("Obviosuly no more mecas, but we should not have been here ...")
				return 0
			}
			Else
			{
				Log("sending meca ...")
				OtherResCollected := OtherResCollected + 1
				NumFreeMecas := NumFreeMecas - 1
				
				if (NumFreeMecas = 0)
				{
					Log("Looks like we have no more free mecas, exiting")
					return 0
				}
			}
			
		}
		
		CurrentRes := CurrentRes  + 1
	}
	
	return 1
}


