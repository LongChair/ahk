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
global Collecting := []
global Pirates := []

; ressources counters
global ScanAvailMine := 0
global ScanAvailAllium := 0
global ScanAvailCrystals := 0
global ScanMiningMecas := 0
global ScanCrystalingMecas := 0
global ScanAlliumingMecas := 0
global ScanPirates := 0
global ScanPiratesRes := 0


;*******************************************************************************
; CountResByType : Returns the amount of scanned ressources with a given type
;*******************************************************************************
CountResByType(ResList, ResType)
{
	CurrentRes := 1
	Amount := 0
    
	Loop, % ResList.Length()
	{
		RefValues := StrSplit(ResList[CurrentRes], ",")
		if (RefValues[1] = ResType)
			Amount := Amount + 1
			
		CurrentRes := CurrentRes +1
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
    if NovaFindClick("buttons\2D.png", 30, "w1000 n0", FoundX, FoundY, 1450, 640, 1760, 820)
    {
        Log("Switching to 2D")
        if !NovaFindClick("buttons\3D_dot.png", 50, "w5000 n1", FoundX, FoundY, 1475,645, 1760, 800)
        {
            Log("ERROR : Failed to find the 3D dot to click, stopping", 2)
            return 0
        }
		
		; wait eventually for system screen
		if !WaitNovaScreen("SYSTEME", 10)
		{
			return 0
		}

    }
    else
    {
        Log("Already in 2D")
    }

    
    return 1
}

;*******************************************************************************
; RecallMecas : Will recall mecas mining the given ressource in the given list
; Amount : amount of mecas to recall
; returns the amount recalled
;*******************************************************************************
RecallMecas(ByRef ResList, ResType, Amount)
{
	global MainWinW, MainWinH
	CurrentRes := 1
	Recalled := 0
    
	Loop, % ResList.MaxIndex()
	{
		; if we have recalled enough, just exit
		if (Recalled = Amount)
			Return Recalled
		
		; if we have a meca mining right type of resource
		RefValues := StrSplit(ResList[CurrentRes], ",")
		MecaX := RefValues[2]
		MecaY := RefValues[3]
		
		if (RefValues[1] = ResType)
		{
				; go to the ressource position
			Log(Format("Recalling meca collecting {1} at ({2:i}, {3:i} ...", ResType, MecaX, MecaY), 1)
			MapMoveToXY(MecaX, MecaY)


			; Click on the ressource
			NovaMouseMove(MainWinW / 2, MainWinH / 2)
			
			NovaLeftMouseClick(MainWinW / 2, MainWinH / 2)
			
			; click collect button
			Log("recalling it ...")
			if !NovaFindClick("buttons\rappeler.png", 70, "w2000 n1")
			{
				Log("ERROR : failed to find recall button, exiting.", 2)
				return 0
			}
			
			Recalled := Recalled + 1
		}
			
		CurrentRes := CurrentRes + 1
	}
	
	return Recalled
}


;*******************************************************************************
; CollectResources : Parse configured system and collect ressources if any
; by sending workers onto them
;*******************************************************************************
CollectResources()
{
	global PlayerName, NumFreeMecas
	
    FullPath =  %A_ScriptDir%\%PlayerName%.ini
    	
	SystemIndex := 1
	Loop
	{
		; check if we have free mecas
		if (NumFreeMecas <= 0)
		{
			LOG("No More Mecas, Exiting ressource collection ...")
			return 1
		}
		
		; Get player name
		Key := "System" . SystemIndex
		
		; Read System
		IniRead, SystemName, %FullPath%, SYSTEMS, %Key%, %A_Space%
		if (SystemName = "")
			break

        ; go to system
        if (!GotoSystem(SystemName))
        {
            LOG("ERROR : Failed to got to system " . SystemName . ", exiting ...")
            return 0
        }
        
        ; collect ressources
        LOG("Collecting ressources in" . SystemName . "...")
        ScanResourcesInSystem(SystemName)
			
		SystemIndex := SystemIndex + 1
	}
	
	return 1
}

;*******************************************************************************
; CollectResourcesInSystem : Parse given system and collect ressources if any
; by sending workers onto them
;*******************************************************************************
ScanResourcesInSystem(system)
{
    global Ressources, Collecting, Pirates
    global NumFreeMecas
	global ScanAvailMine, ScanAvailAllium, ScanAvailCrystals, ScanMiningMecas, ScanCrystalingMecas, ScanAlliumingMecas, ScanPirates, ScanPiratesRes
	global MapPosX, MapPosY
	global ResPriority1, ResPriority2, ResPriority3
    
    Log("Starting to scan map...")
    
    ; we need the system screen
    if !GotoSystem(system)
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
	Collecting := []
    Pirates    := []
	MapPosX := 0
	MapPosY := 0
	
	; Scan the map for ressources
	ScanMap()
	
	; remove duplicate ressources
	Log("Sorting ressources ...")
	SortResList(Ressources)
	Log("We have " . Ressources.Length() . " ressources left after sorting")
	
	Log("Sorting collecting mecas ...")
	SortResList(Collecting)
	Log("We have " . ScanMiningMecas.Length() . " meca Collecting left after sorting")

	Log("Sorting pirates ...")
	SortResList(Pirates)
	Log("We have " . Pirates.Length() . " pirates left after sorting")

	
	ScanAvailMine := CountResByType(Ressources, "MINE")
	ScanAvailAllium := CountResByType(Ressources, "ALLIUM")
	ScanAvailCrystals := CountResByType(Ressources, "CRYSTALS")
    ScanPiratesRes := CountResByType(Ressources, "PIRATERES")
	ScanMiningMecas := CountResByType(Collecting, "MINING")
	ScanCrystalingMecas := CountResByType(Collecting, "CRYSTALING")
	ScanAlliumingMecas := CountResByType(Collecting, "ALLIUMING")
    ScanAlliumingMecas := CountResByType(Collecting, "ALLIUMING")
    ScanPirates := CountResByType(Pirates, "PIRATE")

	
	Log("Scan reported :")
	Log(" - Mine         : " . ScanAvailMine)
	Log(" - Allium       : " . ScanAvailAllium)
	Log(" - Crystals     : " . ScanAvailCrystals)
	Log(" - Mining M.    : " . ScanMiningMecas)
	Log(" - Crystaling M.: " . ScanCrystalingMecas)
	Log(" - Alliuming M. : " . ScanAlliumingMecas)
    Log(" - Pirates      : " . ScanPirates)
	Log(" - Pirate Res   : " . ScanPiratesRes)
	
    
    SaveRessourcesLists()
	
	; now try to grab the ressource
	;if (NumFreeMecas = 0) 
	;{
	;	if (ScanMiningMecas AND (ScanAvailAllium OR ScanAvailCrystals))
	;	{
	;		ToRecall := ScanAvailAllium + ScanAvailCrystals
	;		Log("We need to recall " . ToRecall . ", we have " . ScanMiningMecas . " that can be.", 1)
	;		
	;		Recalled := RecallMecas(Collecting, "MINING", ToRecall)
	;		Log("We recalled " . Recalled . " mecas.", 1)
	;	}
	;	else
	;	{
	;		Log("No free meca, and no important ressource requiring recall, ending.")
	;	}
	;}
	;Else
	;{
	;	if CollectRessourcesByType("ALLIUM")
	;		if CollectRessourcesByType("CRYSTALS")
	;			CollectRessourcesByType("MINE")
	;}
	
	;if CollectRessourcesByType(ResPriority1)
		;if CollectRessourcesByType(ResPriority2)
			;CollectRessourcesByType(ResPriority3)
			
    Log("End of map scan.")
	
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
    ;CurrentX := -1000
    ;CurrentY := 1000
	;MapStepX := 1000
    ;MapStepY := 500
	LoopY := 7
	LoopX := 4
	;LoopY := 5
	;LoopX := 3

	Dir := 1
	
	; Scan the ressources on the map and fill the ressources array
	; Loop Y
	Loop, % LoopY
	{
		; Loop X
		Loop, % LoopX
		{
			MapMoveToXY(CurrentX, CurrentY)

			FindRessources()
		
			CurrentX := CurrentX + MapStepX
	
		}
		
		CurrentX := CurrentX - MapStepX
		MapStepX := -MapStepX
		CurrentY := CurrentY - MapStepY
	}
	
	Log("ScanMap found " . Ressources.Length() . " Ressources")
	
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
	global Farming
    
	CurrentResType := "STATION"
	NovaFindClick("pirates\station.png", 90, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		
	if (Farming)
	{
		CurrentResType := "PIRATE"
		NovaFindClick("pirates\pirate.png", 70, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		
		CurrentResType := "PIRATERES"
		NovaFindClick("resources\pirate.png", 30, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)	
	}
	Else
	{
		CurrentResType := "ALLIUM"
		NovaFindClick("resources\HD_Allium.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)	
		NovaFindClick("resources\HD_Planet_Allium.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		
		CurrentResType := "CRYSTALS"
		NovaFindClick("resources\HD_Crystals.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		NovaFindClick("resources\HD_Planet_Crystals.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		
		CurrentResType := "MINE"
		NovaFindClick("resources\HD_Mine.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		NovaFindClick("resources\HD_Planet.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		
		;CurrentResType := "MINING"
		;NovaFindClick("resources\HD_Mining.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		;NovaFindClick("resources\Planet_Mining.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		;
		;CurrentResType := "CRYSTALING"
		;NovaFindClick("resources\HD_Crystaling.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		;NovaFindClick("resources\Planet_Crystaling.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		;
		;CurrentResType := "ALLIUMING"
		;NovaFindClick("resources\HD_Alliuming.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		;NovaFindClick("resources\Planet_Alliuming.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	}
    
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
    global Ressources, Collecting
	global StationX, StationY
    
	ResX := (ResX - MainWinX - (MainWinW / 2)) + MapPosX
	ResY := MapPosY - (ResY - MainWinY - (MainWinH / 2))

	if CurrentResType in ALLIUM,MINE,CRYSTALS,PIRATERES
	{
        Log(Format("Found a resource at ({1:i},{2:i}) with type {3}, Total={4}", ResX, ResY, CurrentResType, Ressources.Length()))
		Ressources.Insert(CurrentResType . "," . ResX . "," . ResY)
	}

	if CurrentResType in  MINING,CRYSTALING,ALLIUMING
	{
		Collecting.Insert(CurrentResType . "," . ResX . "," . ResY)
		Log(Format("Found a meca collecting resource at ({1:i},{2:i}) with type {3}, Total={4}", ResX, ResY, CurrentResType, Collecting.Length()))
	}
	
	if CurrentResType in PIRATE
    {
        Log(Format("Found a pirate at ({1:i},{2:i}) Total={3}", ResX, ResY, Pirates.Length()))
		Pirates.Insert(CurrentResType . "," . ResX . "," . ResY)
    }
	
	if CurrentResType in STATION
    {
        Log(Format("Found STATION at ({1:i},{2:i})", ResX, ResY))
		StationX := ResX
		StationY := ResY
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
	Loop, % ResList.Length()
	{
		RefValues := StrSplit(ResList[CurrentRes], ",")
		
		CompareRes := CurrentRes + 1
		Loop, % ResList.Length() - CurrentRes
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
	Loop, % Ressources.Length()
	{
		RefValues := StrSplit(Ressources[CurrentRes], ",")
		ResX := RefValues[2]
		ResY := RefValues[3]

		; Check ressource Type
		if (RefValues[1] = ResType)
		{
			; go to the ressource position
			Log(Format("Going to collect {1} at ({2:i}, {3:i} ...", ResType, ResX, ResY), 1)
			MapMoveToXY(ResX, ResY)

			
			; click collect button
			Log("Collecting it ...")
            Ret := ClickMenuImage(MainWinW / 2, MainWinH / 2, "buttons\collect.png", "ValidateRessource")
			if (Ret = 0)
			{
				Log("ERROR : failed to find collect button, skipping.", 2)
				goto CollectRessourcesByType_Next
			}
			
            if (Ret = 1)
            {
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
                        return 1
                    }
                }
             }
			
		}

CollectRessourcesByType_Next:
		CurrentRes := CurrentRes  + 1
	}
	
	return 1
}

;*******************************************************************************
; SaveRessourcesLists : Saves the ressources to files
;*******************************************************************************
SaveRessourcesLists()
{
    SaveListToFile(Ressources, "Ressources.txt")
    SaveListToFile(Collecting, "Collecting.txt")
    SaveListToFile(Pirates, "Pirates.txt")
}

;*******************************************************************************
; SaveListToFile : Saves the ressource list to a given file
;*******************************************************************************
SaveListToFile(ByRef ResList, OutputFile)
{
    FileDelete %OutputFile%
    
    CurrentRes := 1
	Loop, % ResList.Length()
	{
        Text := ResList[CurrentRes] . "`r`n"
        FileAppend %Text%, %OutputFile%
		CurrentRes := CurrentRes + 1
	}
    
}

;*******************************************************************************
; LoadRessourcesLists : Load the ressources lists
;*******************************************************************************
LoadRessourcesLists()
{
    LoadListsFromFile(Ressources, "Ressources.txt")
    LoadListsFromFile(Collecting, "Collecting.txt")
    LoadListsFromFile(Pirates, "Pirates.txt")
}

;*******************************************************************************
; LoadListsFromFile : Load the ressource list from a given file
;*******************************************************************************
LoadListsFromFile(ByRef ResList, InputFile)
{
    Loop, read, %InputFile%
    {
        ResList.Insert(A_LoopReadLine)
    }
}


;*******************************************************************************
; ValidateRessource : check teh on screen displayed ressource to see if 
; it's valid
;*******************************************************************************
ValidateRessource()
{  
    return 1
}

