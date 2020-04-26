#include globals.ahk
#include libs\FindClick.ahk

;*******************************************************************************
; NovaMouseMove : Moves the mouse in screen Coords relative to Nova screen
; X, Y are relative to Nova Window
;*******************************************************************************
NovaMouseMove(X,Y)
{
    global MainWinX, MainWinY
    MouseMove MainWinX + X, MainWinY + Y, 0
}

;*******************************************************************************
; NovaLeftMouseClick : Left click in screen Coords relative to Nova screen
; X, Y are relative to Nova Window
;*******************************************************************************
NovaLeftMouseClick(X,Y)
{
    global MainWinX, MainWinY
    MouseClick L, MainWinX + X, MainWinY + Y
}

;*******************************************************************************
; NovaDragMouse : Spans the screen starting at X,Y for SpanX, SpanY
;*******************************************************************************
NovaDragMouse(X, Y, SpanX, SpanY)
{
	XMargin := 100
	YMargin := 100
	
	X := X - (SpanX / 2)
	Y := Y - (SpanY / 2)
		
	MouseMove, X, Y
	SendEvent {Click down}
	Sleep, 200
	MouseMove, X + SpanX, Y + SpanY, 10
	SendEvent {click up}
	Sleep, 500
}

;*******************************************************************************
; NovaEscapeClick : Left click in an area that should close any contextual menu
;*******************************************************************************
NovaEscapeClick()
{
	global Window_ID
	WinActivate, ahk_id %Window_ID%
	Send, {Esc}
}

;*******************************************************************************
; Log : Logs a string into the log file
; Text : text to log
; Level :
; 0 is default
; 1 is major
; 2 is error
;*******************************************************************************
Log(Text, Level := 0)
{
	global PlayerName
	
	FileName := ""
	
    ; Major Log
    if (Level & 0x1)
		FileLog(Text, A_ScriptDir . "\" . PlayerName . "-MajorLog.txt")
        
    ; Error Log
    if (Level & 0x2)
		FileLog(Text, A_ScriptDir . "\" . PlayerName . "-ErrorLog.txt")


	FileLog(Text, A_ScriptDir . "\" . PlayerName . "-Log.txt")	
}

;*******************************************************************************
; Log : Logs a string into the log file
; Text : text to log
; Level :
; 0 is default
; 1 is major
; 2 is error
;*******************************************************************************
FileLog(Text, Filename)
{
DoLog:
    FileAppend, %A_Hour%:%A_Min%:%A_Sec% - %Text%`r`n,  %FileName%
	if (ErrorLevel = 1)
	{
		Err := A_LastError
		Sleep, 30
		Goto DoLog
	}
}

;*******************************************************************************
; NovaFindClick : Find an image into the window
; Filename : File Path realtive to  %A_ScriptDir%
; Options : FindClick additionnal options
; X1, Y1, X2, Y2 : Coordinates of the region to look in in window coordinates
; FoundX, FoundY : Coordinates of the point found
;*******************************************************************************
NovaFindClick(FileName, Variation, Options, Byref FoundX := 0 , Byref FoundY := 0 , X1 := 0, Y1 := 0, X2 := -1, Y2 := -1)
{   
	global WindowName, Window_ID
	global MainWinW, MainWinH
	
    if (X2 = -1)
        X2 := MainWinW - 1
    if (Y2 = -1)
        Y2 := MainWinH - 1
    
    W := X2 - X1 + 1
    H := Y2 - Y1 + 1
    
	;Opts := "r""" . WindowName . """ oTransBlack," . Variation . " Count a" . X1 . "," . Y1 . "," . W . "," . H . " " . Options
	Opts := "r" . Window_ID . " Silent oTransBlack," . Variation . " Count a" . X1 . "," . Y1 . "," . W . "," . H . " " . Options
    FullPath = %A_ScriptDir%\images\%FileName%
    
	C := FindClick(FullPath, Opts, FoundX, FoundY)
	
	; in case we clicked, wait a bit 
	if (C)
		Sleep, 500
		
	return C
}

;*******************************************************************************
; FindImage : Find an image into the window
; Filename : File Path realtive to  %A_ScriptDir%
; X1, Y1, X2, Y2 : Coordinates of the region to look in in window coordinates
; FoundX, FoundY : Coordinates of the point found
;*******************************************************************************
FindImage(FileName, X1, Y1, X2, Y2, ByRef FoundX :=0, ByRef FoundY :=0, Variation := 0)
{
    global MainWinX, MainWinY
    
    CoordMode, Pixel, Screen
    Options := "*" . Variation . " *Trans0x000000 " .  A_ScriptDir . "\images\" . FileName
    ImageSearch, FoundX, FoundY, MainWinX + X1, MainWinY + Y1, MainWinX + X2, MainWinY + Y2,  %Options%
    
	If ErrorLevel = 0
	{
        FoundX := FoundX - MainWinX
        FoundY := FoundY - MainWinY
		return 1
	}
	else
	{
		return 0
	}
}

;*******************************************************************************
; WaitImage : Waits to find an image into the window
; Filename : File Path realtive to  %A_ScriptDir%
; X1, Y1, X2, Y2 : Coordinates of the region to look in in window coordinates
; FoundX, FoundY : Coordinates of the point found
; Timeout : timeout for the wait in ms
;*******************************************************************************
WaitImage(FileName, X1, Y1, X2, Y2, Timeout, Byref FoundX, Byref FoundY, Variation)
{
	found = 0
	
	While (not found) and (Remaining > 0)
	{
		if (FindImage(FileName, X1, Y1, X2, Y2, FoundX, FoundY, Variation))
		{
			found := 1
            return 1
		}
		else
		{
			sleep, 500
            Remaining := Remaining  - 0.5
		}
	}
    
    return 0
}

;*******************************************************************************
; WaitNoImage : Waits to find an image into the window
; Filename : File Path realtive to  %A_ScriptDir%
; X1, Y1, X2, Y2 : Coordinates of the region to look in in window coordinates
; Timeout : timeout for the wait in ms
;*******************************************************************************
WaitNoImage(FileName, X1, Y1, X2, Y2, Timeout, Variation)
{
	found = 1
    Remaining := Timeout
	
	While (found) and (Remaining > 0)
	{
		if (!FindImage(FileName, X1, Y1, X2, Y2, FoundX, FoundY, Variation))
		{
			found := 0
            return 1
		}
		else
		{
			sleep, 500
            Remaining := Remaining  - 0.5
		}
	}
    
    return 0
}

;*******************************************************************************
; NovaGrab : Grabs an area of the window and store it to the grab directory
; X1, Y1, W, H : Coordinates of the region to look in in window coordinates
; The grabbed image will have the Date/time as filename
;*******************************************************************************
NovaGrab(X, Y, W, H)
{
    global MainWinX, MainWinY
	global PlayerName
    
    GrabPath := A_ScriptDir . "\images\grab\" . PlayerName . "\" . A_MM . "-" . A_DD
    FullPath := GrabPath . "\" . A_Hour . "-" . A_Min . "-" . A_Sec . ".png"
    
    ; create the directory if it doesn't exist
    if !FileExist(GrabPath)
    {
        Log("Creating directory " . GrabPath)
        FileCreateDir, %GrabPath%
    }
    
    Log("Grabbing area at (" . X . "," . Y . ") , (" . W . "x" . H . ")  to " . FullPath )
    
	; Start lightshot by pressing PrintScreen key
	Send, {PrintScreen}
    Sleep, 1000
	
	; Now select the area to grab
	X2 := X + W
	Y2 := Y + H
    MouseClickDrag, L, MainWinX + X, MainWinY + Y, MainWinX + X2, MainWinY + Y2
	
	; now click on teh save button
    SaveX := X2 - 45
    SaveY := Y2 + 20
	Sleep, 1000
    NovaLeftMouseClick(SaveX, SaveY)
    Sleep, 1000
	
	; now send the full path to save to
    Send, %FullPath%
    Sleep, 1000
	
	; validate by pressing enter
    Send, {Enter}
}

;*******************************************************************************
; MapMoveToXY : Move to a position on the map, using mouse scrolls
; Will return maintain MapPosX and MapPosY
;*******************************************************************************
MapMoveToXY(X, Y)
{
    global MapPosX, MapPosY
    global MainWinW, MainWinH
	
    StepX := 1000
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
; GetAvailableMecaCount : Checks how many free mecas we have
;*******************************************************************************
GetAvailableMecaCount(ByRef NumMecas)
{
	global MaxPlayerMecas
	
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
	AtWork := NovaFindClick("buttons\mecatelier.png", 50, "e w1000 n0", FoundX, FoundY, 780, 220, 1340, 960)
	
	PopRightMenu(0)	
	
	NumMecas := MaxPlayerMecas - AtWork
	
	return 1
}


;*******************************************************************************
; GotoSystem : Navigate to the given system
; SystemName : System to go to or empty for current
;*******************************************************************************
GotoSystem(SystemName)
{
    global PlayerName, CurrentSystem
        
    ; default to current system if unspecified
    if (SystemName = "")
        SystemName := CurrentSystem
    
    ; we need the system screen
    LOG("Going to galaxy screen ...")
    if !GotoScreen("GALAXIE", 60)
    {
        return 0
    }


    if (NovaFindClick(Format("systems\{1}\{2}.png", CurrentSystem , SystemName), 70, "w15000 n1"))
    {
		Sleep, 3000
		
		NovaLeftMouseClick(1280, 930)
                    
		Sleep, 5000
		
		; make sure we reached the system
		if !GotoScreen("SYSTEME", 60)
		{
			return 0
		}
		
		CurrentSystem := SystemName
		
		return 1
    }
    Else
    {
        LOG("ERROR : Failed to find " . SystemName . " in the galaxy")
        return 0
    }
    
}

;*******************************************************************************
; RecallAllMecas : Brings back mecas to station
;*******************************************************************************
RecallSomeMecas(Amount)
{
    LOG("Recalling mecas...")
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
    Count := 0
    while (Count <= Amount)
    {
        ; click a meca
        if (NovaFindClick("buttons\recuperation.png", 50, "w2000 n1", FoundX, FoundY, 750, 220, 1340, 960))
        {            
            LOG("Recalling one meca...")
            if (!NovaFindClick("buttons\fleet_rappeler.png", 30, "w6000 n1"))
            {
                LOG("ERROR : Could not fidn recall button while trying to recall meca")
                return 0
            }
            
            Count := Count + 1
			Sleep, 1000

        }
        Else
        {
            Log("No more mecas to recall.")
            break
        }
    }
    
    ; now wait for them to be back to station
    LOG(Format("We recalled {1} mecas.", Count))
    LOG("Waiting for mecas to be back to station...")
    while (NovaFindClick("buttons\mecatelier.png", 80, "w1000 n0", FoundX, FoundY, 750, 220, 1340, 960))
    {
        Sleep, 1000
    }
	
	PopRightMenu(0)	

	return 1    
}


;*******************************************************************************
; RecallAllFleets : Brings fleets back to station
;*******************************************************************************
RecallAllFleets()
{
    global MaxPlayerFleets
    
    ; popup the main menu
    if !PopRightMenu(1, "FLEETS")
    {
        Log("ERROR : failed to popup main menu for fleets. exiting", 2)
        return 0
    }
		
	FleetIndex := 1
	Recalled := []
	Loop, % MaxPlayerFleets
	{
		Recalled[FleetIndex] := 0
		FleetIndex := FleetIndex  + 1
	}
	
	LOG("Recalling fleets...")
	LoopCount := 0
	
	Loop
	{	
		FleetIndex := 1
            
		Loop, % MaxPlayerFleets
		{
		
			GetFleetArea(FleetIndex, X1, Y1, X2, Y2)
			
			if (!Recalled[FleetIndex])
			{
				if (NovaFindClick("buttons\AQuai.png", 50, "w100 n0", FoundX, FoundY, X1, Y1 , X2, Y2))
				{
					; fleet is already docked
					Recalled[FleetIndex] := 1
				}
				Else
				{				
					; first try to click recall Button
					if (NovaFindClick("buttons\recall_button.png", 50, "n1", FoundX, FoundY, X1, Y1 , X2, Y2))
					{
						Recalled[FleetIndex] := 1
					}
					Else
					{
						; click on the fleet
						NovaLeftMouseClick(X1 + 20, Y1 +20)
						
						
						if NovaFindClick("buttons\fleet_window_recall.png", 70, "w2000 n1")
						{
							LOG(Format("Recalling fleet #{1}/{2} ...", FleetIndex, MaxPlayerFleets))
							Recalled[FleetIndex] := 1
							Sleep, 500
							NovaEscapeClick()
							
							; wait for window to vanish
							NovaFindClick("buttons\fleets_on.png", 30, "w5000 n1")
						}					
					}
				}
			}
			
			FleetIndex := FleetIndex + 1
		}
		
		FleetIndex := 1
		Count := 0
		Loop, % MaxPlayerFleets
		{
			if (Recalled[FleetIndex])
				Count := Count + 1
			FleetIndex := FleetIndex  + 1
		}
		
		LoopCount := LoopCount + 1
		if (LoopCount >= 50)
		{
			Log("ERROR : failed to recall all fleets (timeout). exiting", 2)
			return 0
		}
	
	} until (Count >= MaxPlayerFleets)
		
    ; now wait for them to be back to station
    LOG(Format("We recalled {1} fleet(s).", Recalled))
    
	PopRightMenu(0)	

	return 1    
}


;*******************************************************************************
; WaitForFleetsIdle : wait for all fleets to be idle
;*******************************************************************************
WaitForFleetsIdle(TimeOut := 100)
{
	global MaxPlayerFleets
    
	ZeroTimeCount := 0
	
    ; Open the fleets tab
    if !PopRightMenu(1, "FLEETS")
    {
        Log("ERROR : failed to popup main menu for fleets. exiting", 2)
        return 0
    }
    
	TimeLeft := TimeOut * 2
	Loop
	{
		IdleCounter := 0
		NovaFindClick("buttons\recall_button.png", 70, "e n0 FuncHandleIdleCount", FoundX, FoundY, 1320, 185, 1585, 920)
		NovaFindClick("buttons\manage_button.png", 70, "e n0 FuncHandleIdleCount", FoundX, FoundY, 1320, 185, 1585, 920)
		
		if (IdleCounter >= MaxPlayerFleets)
		{
			break
		}
		
		Sleep, 500
		
		TimeLeft := TimeLeft - 1
        if (TimeLeft <= 0)
        {
            Log(Format("ERROR : timeout after {1} seconds waiting for fleets to be in state Idle. exiting", TimeOut), 2)
			PopRightMenu(0)	
            return 0
        }
		
		if (NovaFindClick("buttons\zerotime.png", 30, "n0", FoundX, FoundY, 1000, 185, 1350, 880))
		{
			ZeroTimeCount := ZeroTimeCount + 1
		}
		Else
		{
			ZeroTimeCount := 0
		}
		
		if (ZeroTimeCount >= 10)
		{
			Log("ERROR : Zero Time detected, connection from somewhere else ?" )
			PopRightMenu(0)	
            return 0
		}
	}
		
		
		
    ; wait for all fleets to be idle
    ;TimeLeft := TimeOut * 10
	;
	;Log("Waiting for all fleets to be idle ...")
    ;Loop
    ;{	
		;Idle := CountFleetsState("buttons\EnAttente.png")
		;
		;if (Idle >= MaxPlayerFleets)
		;{
			;break
		;}
          ;
        ;Sleep, 100
        ;TimeLeft := TimeLeft - 1
        ;
        ;if (TimeLeft <= 0)
        ;{
            ;Log(Format("ERROR : timeout after {1} seconds waiting for fleets to be int state {2}. exiting", TimeOut, ImageState), 2)
			;PopRightMenu(0)	
            ;return 0
        ;}
    ;}
	

    ; fold again right menu
	PopRightMenu(0)	
    
    return 1  
}

;*******************************************************************************
; GetFirstIdleFleet : Returns the index of first idle fleet (1 to 6), 0 if none 
;*******************************************************************************
GetFirstIdleFleet(TimeOut := 100)
{
	global MaxPlayerFleets, IdleFleet
    
	ZeroTimeCount := 0
	StartY := 193
	YStep := 122
	
    ; Open the fleets tab
    if !PopRightMenu(1, "FLEETS")
    {
        Log("ERROR : failed to popup main menu for fleets. exiting", 2)
        return 0
    }
    
	TimeLeft := TimeOut * 2
	Loop
	{
		IdleFleet := 0
		if NovaFindClick("buttons\manage_button.png", 70, "n0", FoundX, FoundY, 1320, 185, 1585, 920)
		{
			IdleFleet := Floor((FoundY - StartY) / YStep) + 1 
			break
		}
		

		if NovaFindClick("buttons\recall_button.png", 70, "n0", FoundX, FoundY, 1320, 185, 1585, 920)
		{
			IdleFleet := Floor((FoundY - StartY) / YStep) + 1 
			break
		}
		
		Sleep, 500
		
		TimeLeft := TimeLeft - 1
        if (TimeLeft <= 0)
        {
            Log(Format("ERROR : timeout after {1} seconds waiting for first Idle fleet. exiting", TimeOut), 2)
			PopRightMenu(0)	
            return 0
        }
		
	}

    ; fold again right menu
	PopRightMenu(0)	
    
    return IdleFleet  
}

;*******************************************************************************
; WaitForFleetsMoving : wait for at least a fleet to be moving
;*******************************************************************************
WaitForFleetsMoving()
{   
    ; Open the fleets tab
    if !PopRightMenu(1, "FLEETS")
    {
        Log("ERROR : failed to popup main menu for fleets. exiting", 2)
        return 0
    }
    
	TimeOut := 5
	TimeLeft := TimeOut * 10
	Loop
	{
		IdleCounter := 0
		NovaFindClick("buttons\turbo_button.png", 70, "e n0 FuncHandleIdleCount", FoundX, FoundY, 1320, 185, 1585, 920)
		
		if (IdleCounter > 0)
		{
			break
		}
		
		Sleep, 100
		
		TimeLeft := TimeLeft - 1
        if (TimeLeft <= 0)
        {
            Log(Format("ERROR : timeout after {1} seconds waiting for fleets to be int state Moving. exiting", TimeOut), 2)
			PopRightMenu(0)	
            return 0
        }
	}
	

    ; fold again right menu
	PopRightMenu(0)	
    
    return 1  
}

;*******************************************************************************
; HandleIdleCount : Count Fleets in idle state
;*******************************************************************************
HandleIdleCount(ResX, ResY)
{
	global IdleCounter
	
	IdleCounter := IdleCounter + 1
}

;*******************************************************************************
; CountFleetsState : Count Fleets in a given state by image
;*******************************************************************************
CountFleetsState(ImageState)
{
    global MaxPlayerFleets
    
    ; Open the fleets tab
	CountFleets := 0
	FleetIndex := 1
	
	Loop, % MaxPlayerFleets
	{
		GetFleetArea(FleetIndex, X1, Y1, X2, Y2)
		
		if NovaFindClick(ImageState, 50, "n0", FoundX, FoundY, X1, Y1, X1 + (X2 - X1) / 2, Y1 + (Y2 - Y1) / 2)
		{
			CountFleets := CountFleets + 1
		}
			
		FleetIndex := FleetIndex + 1
	}
		       
            
    return CountFleets
}


;*******************************************************************************
; PopRightMenu : Will pop the main right menu
; Visible : 1 = Show it, 0 = Close it
;*******************************************************************************
PopRightMenu(Visible, TabPage := "ECONOMY")
{
    
    if (Visible)
    {
        Log("Showing Main right menu ...")
		Count := 1
		while (NovaFindClick("buttons\ceg.png", 50, "w2000 n0", FoundX, FoundY, 1750, 50, 1850, 140))
        {
			; click the button to show up the menu
			NovaLeftMouseClick(1780, 525)
			Sleep, 1000
			
			Count := Count  + 1
			if (Count > 10)
			{
				LOG("ERROR : Timeout Waiting for right menu to show up")
				return 0
			}
		}
        
		Count := 1
		Loop 
		{
			if (!NovaFindClick("buttons\" . TabPage . "_on.png", 40, "w100 n0", FoundX, FoundY, 1600, 145, 1800, 680))
			{
				; wait for eventual unselected economy tab
				if NovaFindClick("buttons\" . TabPage . "_off.png", 40, "w2000 n1", FoundX, FoundY, 1600, 145, 1800, 680)
				{
					Log("Selected " . TabPage . " tab in right menu")
				}
			}
			Else
			{
				break
			}
			
			Sleep, 500
			
			
			Count := Count  + 1
			if (Count > 10)
			{
				LOG("ERROR : Timeout Waiting for right menu tab to show up")
				return 0
			}
		}
	    
        ; we found button, that's done
        return 1
        
    }
    else
    {
        Log("Hiding Main right menu ...")
        
        
        ; make sure we don't have the menu bar again
        ; For this we check if we find the CEG icon which is behind
		Count := 1
        while (!NovaFindClick("buttons\ceg.png", 50, "n0", FoundX, FoundY, 1750, 50, 1850, 140))
        {
			; close teh menu
			NovaEscapeClick()
			
			Sleep, 1000
			
			Count := Count  + 1
			if (Count > 30)
			{
				LOG("ERROR : Timeout Waiting for right menu to vanish")
				return 0
			}
        }
        
        return 1
    }
}

;*******************************************************************************
; PeekClosestRes : will peeks the closest ressource from the list to
; the given position
;*******************************************************************************
PeekClosestRes(ByRef ResList, X, Y)
{
	FoundIndex := 0
	CurrentRes := 1
	MinDist := 99999999999999
	
	Loop, % ResList.Length()
	{
	
		RefValues := StrSplit(ResList[CurrentRes], ",")
		ResX := RefValues[2]
		ResY := RefValues[3]
		
		DX := ResX - X
		DY := ResY - Y
		
		Dist := sqrt(DX*DX + DY*DY)
		Radius := sqrt(ResX*ResX + ResY*ResY)
        
		if ((Dist < MinDist) and (Radius < 1800))
		{
			MinDist := Dist
			FoundIndex := CurrentRes
		}

		CurrentRes := CurrentRes + 1
	}
	
	; remove ressource and return it
	if (FoundIndex> 0)
		return ResList.RemoveAt(FoundIndex)
	Else
		return ""
}

;*******************************************************************************
; GetFleetArea : will return the area of the given fleet index
;*******************************************************************************
GetFleetArea(FleetIndex, ByRef X1, ByRef Y1, ByRef X2, ByRef Y2)
{
	if (FleetIndex > MaxPlayerFleets)
	{
		X1 := 0
		Y1 := 0
		X2 := 0
		Y2 := 0
		
	}
	Else
	{
		X1 := 760
		Y1 := 193
		X2 := 1580
		Y2 := 300
		
		Y1 := Y1 + (122 * (FleetIndex - 1))
		Y2 := Y2 + (122 * (FleetIndex - 1))
	}
	
}

;*******************************************************************************
; ClickOnly: will Wait for an image, click it, 
;*******************************************************************************
ClickOnly(Image, Delta := 50, Timeout := 5, X1 := 0, Y1 := 0, X2 := -1, Y2 := -1)
{
	global MainWinW, MainWinH
	
    if (X2 = -1)
        X2 := MainWinW - 1
    if (Y2 = -1)
        Y2 := MainWinH - 1
		
	return NovaFindClick(Image, Delta, "w5000 n1", FoundX, FoundY, X1, Y1, X2, Y2)
}


;*******************************************************************************
; ClickUntilChanged : will Wait for an image, click it, and then wait for 
; it to go
;*******************************************************************************
ClickUntilChanged(Image, Delta := 50, Timeout := 5, X1 := 0, Y1 := 0, X2 := -1, Y2 := -1)
{
	global MainWinW, MainWinH
	
    if (X2 = -1)
        X2 := MainWinW - 1
    if (Y2 = -1)
        Y2 := MainWinH - 1
		
	if (ClickOnly(Image, Delta, Timeout, X1, Y1, X2, Y2))
	{
		Loop
		{
			if (!NovaFindClick(Image, Delta, "w1000 n0", FoundX, FoundY, X1, Y1, X2, Y2))
			{
				return 1
			}
			
			Timeout := Timeout - 1
		
			if (Timeout <= 0)
			{
				LOG("ERROR : Timeout reached waiting for " . Image . " to disappear", 2)
				break
			}
		}
	}
	Else
	{
		LOG("ERROR : cannot find " . Image . " to click it", 2)
	}
	
ClickUntilChanged_Failure:
	return 0
}

;*******************************************************************************
; ClickMenuImage : Click at X,Y and select the given menu image
; will return : 
;   0 if failed
;   1 if succeeded
;  -1 if not valid 
;*******************************************************************************
ClickMenuImage(X,Y, Image, ValidateFunction := "")
{
    Ret := 0
    
    ; Click on the pirate
	Count := 1
	Loop
	{
		
		NovaLeftMouseClick(X, Y)
		
		; make sure we have the menu
		if (!NovaFindClick("buttons\favori.png", 80, "w3000 n0", FoundX, FoundY, 500,175, 1600, 875))
		{
			If (Count >= 3)
			{
				LOG("ERROR : could not find menu, while trying to click on " . Image, 2)
				return 0
			}
		}
		Else
		{ 
			break
		}
			
		Count := Count + 1
	}
    
    if (ValidateFunction <> "")
    {
        if (not %ValidateFunction%())
        {
            LOG("Ressource is not valid, skipping")
            Ret := -1
            goto ClickMenuImage_End
        }
    }
    
    ; we look for the image
    if (!NovaFindClick(Image, 70, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
    {
        LOG("ERROR : Could Not find the menu image " . Image . ", different menu popped up ?", 2)        
    }
    Else
    {
        Ret := 1
    }
    
ClickMenuImage_End:  
    ; wait for menu to vanish
	NovaEscapeMenu()
	
    return Ret
}

;*******************************************************************************
; NovaEscapeMenu : Click at X,Y and select the given menu image
;*******************************************************************************
NovaEscapeMenu()
{
	 ; wait for menu to vanish
    if (NovaFindClick("buttons\favori.png", 50, "n0", FoundX, FoundY, 500,175, 1600, 875))
    {
        NovaEscapeClick()
		Sleep, 2000
    }
	
	Count := 0
	while (NovaFindClick("buttons\favori.png", 50, "w100 n0", FoundX, FoundY, 500,175, 1600, 875) and (Count < 10))
	{
		Sleep, 500
		Count :=  Count + 1
	}
	
	if (Count >= 10)
	{
		Log("ERROR : timeout while trying to escape menu, exiting")
		return 0
	}
	
	return 1
}

;*******************************************************************************
; ReadjustPosition() : readjusts the position with centering on station
;*******************************************************************************
ReadjustPosition()
{
	global MapPosX, MapPosY
	global StationX, StationY
	global CurrentSystem
	
	;Log("Recentering on station ...")

	; click on my station button
	if NovaFindClick("screen_markers\my_station.png", 50, "w2000 n1", FoundX, FoundY, 270, 845, 420, 980)
	{
		; wait until we find the station, but could be hard to detect
		NovaFindClick("pirates\station.png", 50, "w4000 n0", FoundX, FoundY, 840, 490, 960, 600)
	
		MapPosX := StationX
		MapPosY := StationY
		
		;Log("Recentering completed")
		return 1	
	}
	Else
	{
		LOG("ERROR : Failed to find station button for recentering")
		return 0
	}
}

;*******************************************************************************
; RepairAllFleets() : Trigers all fleets repairs
;*******************************************************************************
RepairAllFleets()
{

	; we need to be in station screen
	if !GotoScreen("STATION", 60)
    {
        return 0
    }
	
	; Click on dock
	if !NovaFindClick("buttons\dock.png", 30, "w1000 n1")
	{
		Log("ERROR : failed to find & click dock button, exiting")
		return 0
	}
	
	; Wait for dock screen to be here
	if !NovaFindClick("buttons\quai.png", 30, "w5000 n0")
	{
		Log("ERROR : failed to wait for sock screen, exiting")
		return 0
	}
	
	Loop, %MaxPlayerFleets%
	{
		; select fleet Tab
		LOG(Format("Selecting tab for Fleet {1}", A_Index))
		NovaLeftMouseClick(264 * A_Index + 130, 180)
		
		if NovaFindClick("buttons\dock_repair.png", 30, "w1000 n1")
		{
			LOG(Format("Repairing Fleet {1}", A_Index))
			
			if NovaFindClick("buttons\dock_repair_free.png", 30, "w1000 n1")
			{
				LOG(Format("Finishing repair for Fleet {1} for free", A_Index))
			}
		}
		
		Sleep, 500
	}
	
	; now get back from screen
	LOG("Going out of dock screen ...")
	if !NovaFindClick("buttons\dock_back.png", 30, "w5000 n1")
	{
		Log("ERROR : failed to get back from dock screen, exiting")
		return 0
	}
		
	return 1
}


;*******************************************************************************
; FormatSeconds() : Convert the specified number of seconds to hh:mm:ss format.
;*******************************************************************************
FormatSeconds(NumberOfSeconds)
{
    time = 19990101  ; *Midnight* of an arbitrary date.
    time += %NumberOfSeconds%, seconds
    FormatTime, mmss, %time%, mm:ss
    return NumberOfSeconds//3600 ":" mmss
}

;*******************************************************************************
; GetAttackFleetArea() : Gets the square coordinates for a fleet
;*******************************************************************************
GetAttackFleetArea(FleetIndex, ByRef X1, ByRef Y1, Byref X2, ByRef Y2)
{
	StartX := 697
	EndX := 1143
	StartY := 154
	Height := 130
	I := FleetIndex -1 
	
	X1 := StartX
	X2 := EndX
	Y1 := StartY + I*Height
	Y2 := Y1 + Height	
}

;*******************************************************************************
; GetFleetDist() : Gets the distance from a fleet to a point
;*******************************************************************************
GetFleetDist(FleetIndex, PosX, PosY)
{
	global FleetPosX, FleetPosY
	
		
	DX := FleetPosX[FleetIndex] - PosX
	DY := FleetPosY[FleetIndex] - PosY
		
	Dist := sqrt(DX*DX + DY*DY)
	
	return Dist
}