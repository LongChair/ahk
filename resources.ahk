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
    
	if (NovaFindClick("buttons\3D.png", 50, "w1000 n0", FoundX, FoundY, 1650, 750, 1750, 830))
	{
		Log("System already in 2D")
		return 1
	}
    
    ; Look if pane is already openned
    if !NovaFindClick("buttons\right_menu_off.png", 80, "w500 n0", FoundX, FoundY, 1450, 640, 1760, 820)
    {
        Log("Unfolding 2D/3D menu")
        if !NovaFindClick("buttons\right_menu_on.png", 80, "w1000 n1", FoundX, FoundY, 1750, 640, 1840, 820)
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
    if NovaFindClick("buttons\2D.png", 30, "w1000 n0", FoundX, FoundY, 1640, 640, 1760, 820)
    {
        Log("Switching to 2D")
        if !NovaFindClick("buttons\3D_dot.png", 50, "w5000 n1", FoundX, FoundY, 1600,645, 1760, 800)
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
	global ResPriority1, ResPriority2, ResPriority3
	global CurrentSystem
	
    FullPath =  %A_ScriptDir%\%PlayerName%.ini
    CurrentSystem := FindCurrentSystem()
	StartSystem := CurrentSystem
	LOG("We found " . StartSystem . " as current system.")
	
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
		IniRead, SystemName, %FullPath%, %StartSystem%, %Key%, %A_Space%
		if (SystemName = "")
			break

        ; collect ressources
        LOG("Collecting ressources in " . SystemName . " from " . CurrentSystem . " ...")
        ScanResourcesInSystem(SystemName)
		
		if !CollectRessourcesByType(ResPriority1)
			return 0
		if !CollectRessourcesByType(ResPriority2)
			return 0
		if !CollectRessourcesByType(ResPriority3)
			return 0
			
		SystemIndex := SystemIndex + 1
	}
	
	return 1
}

;*******************************************************************************
; FindCurrentSystem : determines which is the current system based on known
; systems
;*******************************************************************************
FindCurrentSystem()
{
	; go to galaxy screen
	if (!GotoScreen("GALAXIE",30))
	{
		return 0
	}
	
	FoundSystem := ""
	SystemDirectory = %A_ScriptDir%\images\systems
	LoopCount := 15
	
	while (LoopCount > 0)
	{
		Loop, Files, %SystemDirectory%\* , D
		{
			SystemPath = %A_LoopFileShortPath%
			SystemName = %A_LoopFileShortName%
			FileName := Format("systems\{1}\{2}.png", SystemName, SystemName)
			
			if (NovaFindClick(FileName, 70, "w100 n0", FoundX, FoundY, 850, 480,950, 580))
				return %SystemName%
		}
		Sleep, 1000
		LoopCount := LoopCount - 1
	}
	
	return ""
}

;*******************************************************************************
; CollectResourcesInSystem : Parse given system and collect ressources if any
; by sending workers onto them
;*******************************************************************************
ScanResourcesInSystem(SystemName)
{
    global Ressources, Collecting, Pirates
    global NumFreeMecas
	global ScanAvailMine, ScanAvailAllium, ScanAvailCrystals, ScanMiningMecas, ScanCrystalingMecas, ScanAlliumingMecas, ScanPirates, ScanPiratesRes
	global MapPosX, MapPosY
	global ResPriority1, ResPriority2, ResPriority3
	global CurrentSystem
    
   
	; default to current system if unspecified
    if (SystemName = "")
	{
		SystemName := FindCurrentSystem()
		CurrentSystem := SystemName
	}
        
	if (SystemName = "")
	{
		Log("Error : Could not identify current system, Is it unknown ?")
		return 0
	}
    
	 Log(Format("Starting to scan map in {1} ...", SystemName))
	
    ; we need the system screen
    ;if !GotoSystem(SystemName)
    ;{
    ;    return 0
    ;}
	
	   
    if (!GotoScreen("SYSTEME", 60))
    {
        Log("ERROR : failed to go to system screen, exiting.", 2)
        return 0
    }
	    
	CurrentSystem := SystemName
    
    ; then go in 2D Mode
    ;if !Toggle2DMode()
    ;{
    ;    Log("ERROR : Failed to toggle 2D mode, exiting.", 2)
    ;    return 0
    ;}

	Ressources := []
	Collecting := []
    Pirates    := []
	MapPosX := 0
	MapPosY := 0
	
	; Scan the map for ressources
	Sleep, 2000
	ScanMap(SystemName)
	
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
ScanMap(SystemName, ScanStation:=1)
{
    global Ressources, PlayerName, CurrentSystem
		
		; default to current system if unspecified
    if (SystemName = "")
        SystemName := CurrentSystem
		
	; get system size
	FullPath =  %A_ScriptDir%\images\systems\%SystemName%\system.ini
	IniRead, SystemWidth, %FullPath%, SYSTEM, WIDTH, 3000
	IniRead, SystemHeight, %FullPath%, SYSTEM, HEIGHT, 3000
	
	
    CurrentX := -(SystemWidth / 2)
    CurrentY :=  (SystemHeight / 2)
	MapStepX := 1000
    MapStepY := 500
	LoopY := (SystemHeight / MapStepY) + 1 
    LoopX := (SystemWidth / MapStepX) + 1 

	Dir := 1
	
	; Scan the ressources on the map and fill the ressources array
	; Loop Y
	Loop, % LoopY
	{
		; Loop X
		Loop, % LoopX
		{
			MapMoveToXY(CurrentX, CurrentY)

			FindRessources(ScanStation)
		
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
FindRessources(ScanStation:=1)
{
	global CurrentResType
    global AreaX1, AreaY1, AreaX2, AreaY2
	global Farming, FarmingMulti, Farming3D
    
	if (ScanStation)
	{
		CurrentResType := "STATION"
		NovaFindClick("pirates\station.png", 50, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
	}
		
	if (Farming Or FarmingMulti Or Farming3D)
	{
		CurrentResType := "PIRATE"
		NovaFindClick("pirates\pirate.png", 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)
		
		;CurrentResType := "PIRATERES"
		;NovaFindClick("resources\pirate.png", 30, "e0.5 n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)	
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
	global WinBorderX, WinBorderY
    
	ResX := (ResX - MainWinX - WinBorderX - (MainWinW / 2)) + MapPosX 
	ResY := MapPosY - (ResY - MainWinY - WinBorderY - (MainWinH / 2))

	if CurrentResType in ALLIUM,MINE,CRYSTALS,PIRATERES
	{
        Log(Format("Found a resource at ({1:i},{2:i}) with type {3}, Total={4}", ResX, ResY, CurrentResType, Ressources.Length()))
		Ressources.Insert(Format("{1},{2:i},{3:i}", CurrentResType, ResX, ResY))
	}

	if CurrentResType in  MINING,CRYSTALING,ALLIUMING
	{
		Collecting.Insert(Ressources.Insert(Format("{1},{2:i},{3:i}", CurrentResType, ResX, ResY)))
		Log(Format("Found a meca collecting resource at ({1:i},{2:i}) with type {3}, Total={4}", ResX, ResY, CurrentResType, Collecting.Length()))
	}
	
	if CurrentResType in PIRATE
    {
        Log(Format("Found a Pirate at ({1:i},{2:i}) Total={3}", ResX, ResY, Pirates.Length()))
		Pirates.Insert(Format("{1},{2:i},{3:i}", CurrentResType, ResX, ResY))
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

global RssDistThreshold

SortStart:
	
	CurrentRes := 1
	Loop, % ResList.Length()
	{
		RefValues := StrSplit(ResList[CurrentRes], ",")
		
		CompareRes := CurrentRes + 1
		Loop, % ResList.Length() - CurrentRes
		{
			CompareValues := StrSplit(ResList[CompareRes], ",")
			
			if (Abs(CompareValues[2] - RefValues[2]) < RssDistThreshold) AND (Abs(CompareValues[3] - RefValues[3]) < RssDistThreshold)
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
	global Ressources_BlackList
	
	if (NumFreeMecas = 0)
	{
		Log("Looks like we have no more mecas, skipping")
		return 1
	}
	
	if (ResType = "")
	{
		Log("Ressource type is empty, skipping")
		return 1
	}
		
	CurrentRes := 1
	CollectError := 0
	
	Log(Format("Collecting ressources found for {1} ", ResType))
	Loop, % Ressources.Length()
	{
		RefValues := StrSplit(Ressources[CurrentRes], ",")
		ResX := RefValues[2]
		ResY := RefValues[3]

		; Check ressource Type
		if (RefValues[1] = ResType)
		{
			; go to the ressource position
			Log(Format("Going to collect {1} at ({2:i}, {3:i}) ...", ResType, ResX, ResY), 1)
			MapMoveToXY(ResX, ResY)

			
			; click collect button
			Log("Collecting it ...")
            Ret := ClickMenuImage(MainWinW / 2, MainWinH / 2, "buttons\collect.png", "ValidateRessource")
			if (Ret = 0)
			{
				Log("ERROR : failed to find collect button, skipping.", 2)
				CollectError := CollectError + 1
				if (CollectError > 5)
				{
					Log("Too many collect failures, we will stop this time")
					return 1
				}
				ReadjustPosition()
				goto CollectRessourcesByType_Next
			}
			
            if (Ret = 1)
            {
                ; eventually click on the OK button if we had no more mecas
                if NovaFindClick("buttons\Ok.png", 50, "w1000 n1")
                {
                    Log("Obviosuly no more mecas, but we should not have been here ...")
										
					; we usually have the context menu still up, close it
					Sleep, 500
					NovaEscapeClick()
                    return 1
                }
                Else
                {
                    Log(Format("sending meca ({1} left) ...", NumFreeMecas))
                    OtherResCollected := OtherResCollected + 1
                    NumFreeMecas := NumFreeMecas - 1
                    
                    if (NumFreeMecas = 0)
                    {
                        Log("Looks like we have no more free mecas, exiting")
                        return 1
                    }
                }
             }
			 
			 ; if ressource is invalid
			 if (Ret = -1)
             {
				Log(Format("Blacklisting ressource {1}", Ressources[CurrentRes]))
				Ressources_BlackList.Insert(Ressources[CurrentRes])
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
; SaveBlackLists : Saves the blackllists to files
;*******************************************************************************
SaveBlackLists()
{
	global PlayerName
	global Pirates_BlackList, Ressources_BlackList
	
	LOG("Saving BlackLists...")
    SaveListToFile(Pirates_BlackList, Format("{1}_Pirates_BlackList.txt", PlayerName))
    SaveListToFile(Ressources_BlackList, Format("{1}_Ressources_BlackList.txt", PlayerName))
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
; LoadBlackLists : Load the black lists
;*******************************************************************************
LoadBlackLists()
{
	global PlayerName
	global Pirates_BlackList, Ressources_BlackList
	
	LOG("Loading BlackLists...")
    LoadListsFromFile(Pirates_BlackList, Format("{1}_Pirates_BlackList.txt", PlayerName))
    LoadListsFromFile(Ressources_BlackList, Format("{1}_Ressources_BlackList.txt", PlayerName))
	Log(Format("We Found {1} pirates and {2} ressources in blacklists.", Pirates_BlackList.Length(), Ressources_BlackList.Length()))
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
	; we check if it's know to be valid
    Loop, Files, %A_ScriptDir%\images\resources\invalid\*.png"
    {
		FileName := "resources\invalid\" . A_LoopFileName
        if NovaFindClick(FileName, 50, "w100 n0", FoundX, FoundY, 575, 475, 750, 600)
		{
			Log(Format("invalidating ressource matching {1}", A_LoopFileName))
            return 0
		}
    }
    
    return 1
}


;*******************************************************************************
; FilterListwithBlackList : Removes list items that are in the blacklist
;*******************************************************************************
FilterListwithBlackList(Byref List, Blacklist)
{
	global RssDistThreshold
	
	ListIndex := 1
	Loop, % List.Length()
	{
		Values := StrSplit(List[ListIndex], ",")
		X := Values[2]
		Y := Values[3]
		
		BlackListIndex := 1
		Loop, % Blacklist.Length()
		{
			BlackValues := StrSplit(Blacklist[BlackListIndex], ",")
			BlackX := BlackValues[2]
			BlackY := BlackValues[3]
			
			if (Abs(X - BlackX) < RssDistThreshold) AND (Abs(Y - BlackY) < RssDistThreshold)
			{
				; we need to remove this one
				Log(Format("Removing {1} at ({2}, {3}) due to blacklist filter", BlackValues[1], BlackValues[2], BlackValues[3]))
				List.RemoveAt(ListIndex)
				goto FilterListwithBlackList_End
			}
			
			BlackListIndex := BlackListIndex + 1
		}
		
		ListIndex := ListIndex + 1
		
FilterListwithBlackList_End:

	}
}

;*******************************************************************************
; RemoveObosoleteBlackList : Removes obsolete blacklist items that are not Close
; to list items
;*******************************************************************************
RemoveObosoleteBlackList(Byref Blacklist, List)
{
	global RssDistThreshold

	BlackListIndex := 1
	Loop, % Blacklist.Length()
	{
		BlackValues := StrSplit(Blacklist[BlackListIndex], ",")
		BlackX := BlackValues[2]
		BlackY := BlackValues[3]
		
		ListIndex := 1
		Valid := 0
		Loop, % List.Length()
		{
			Values := StrSplit(List[ListIndex], ",")
			X := Values[2]
			Y := Values[3]
			
			if (Abs(X - BlackX) < RssDistThreshold) AND (Abs(Y - BlackY) < RssDistThreshold)
			{
				Valid := 1
				break
			}
			
			ListIndex := ListIndex + 1
		}
		
		if (!Valid)
		{
			Log(Format("Removing {1} from black ist as it looks obsolete", Blacklist[BlackListIndex]))
			Blacklist.RemoveAt(BlackListIndex)
		}
		Else
			BlackListIndex := BlackListIndex + 1
		
	}
}

