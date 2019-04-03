﻿#include globals.ahk
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
	Sleep, 500
	SendEvent {click up}
	Sleep, 200
}

;*******************************************************************************
; NovaEscapeClick : Left click in an area that should close any contextual menu
;*******************************************************************************
NovaEscapeClick()
{
	NovaLeftMouseClick(452, 635)
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
	Opts := "r" . Window_ID . " oTransBlack," . Variation . " Count a" . X1 . "," . Y1 . "," . W . "," . H . " " . Options
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
	AtWork := NovaFindClick("buttons\recuperation.png", 80, "e w1000 n0", FoundX, FoundY, 750, 220, 1340, 960)
	
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
    global PlayerName
    
    FullPath =  %A_ScriptDir%\%PlayerName%.ini
 
	; Get the current system we are in
	IniRead, CurrentSystem, %FullPath%, SYSTEMS, Current, ""
    
    ; default to current system if unspecified
    if (SystemName = "")
        SystemName := CurrentSystem
    
    ; we need the system screen
    LOG("Going to galaxy screen ...")
    if !GotoScreen("GALAXIE", 60)
    {
        return 0
    }


    if (NovaFindClick(Format("systems\{1}\{2}.png", CurrentSystem , SystemName), 50, "w10000 n1"))
    {
        
        if (NovaFindClick("buttons\rejoindre.png", 70, "w5000 n1"))
        {
            
            Sleep, 5000
            
            ; make sure we reached the system
            if !GotoScreen("SYSTEME", 60)
            {
                return 0
            }
            
            return 1
        }
        Else
        {
            LOG("ERROR : Failed to find system join button for " . SystemName . ", exiting ...")
            Return 0
        }
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
            if (!NovaFindClick("buttons\meca_Rappeler.png", 30, "w6000 n1"))
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
    
    LOG("Recalling fleets...")
	; popup the main menu
    if !PopRightMenu(1, "FLEETS")
    {
        Log("ERROR : failed to popup main menu for fleets. exiting", 2)
        return 0
    }
		
	FleetIndex := 0
    Loop, % MaxPlayerFleets
    {
        Offset := FleetIndex * 110
        
        ; click on fleet
        NovaLeftMouseClick(1000, 230 + Offset)
        
        
        LOG("Recalling one fleet...")
        if (!NovaFindClick("buttons\Rappeller.png", 80, "w3000 n1"))
        {
            LOG("ERROR : Could not find recall button while trying to recall fleet")
            return 0
        }
        
        FleetIndex := FleetIndex + 1
    }
    
    ; now wait for them to be back to station
    LOG(Format("We recalled {1} fleet.", FleetIndex ))
    
	PopRightMenu(0)	

	return 1    
}

;*******************************************************************************
; WaitForFleetsIdle : wait for all fleets to be idle
;*******************************************************************************
WaitForFleetsIdle()
{
    return WaitForFleetsState("buttons\EnAttente.png", 300)
}

;*******************************************************************************
; WaitForFleetsState : wait for all fleets to be in the given image state
;*******************************************************************************
WaitForFleetsState(ImageState, TimeOut)
{
    global MaxPlayerFleets
    
    ; Open the fleets tab
    if !PopRightMenu(1, "FLEETS")
    {
        Log("ERROR : failed to popup main menu for fleets. exiting", 2)
        return 0
    }
    
    ; wait for all fleets to be idle
    LoopCount := TimeOut
    Loop, % LoopCount
    {
		CountFleets := 0
		FleetCount := 0
		
		Loop, % MaxPlayerFleets
		{
			Offset := FleetCount * 110
			if NovaFindClick(ImageState, 80, "w100 n0", FoundX, FoundY, 750, 180 + Offset, 1200, 290 + Offset)
			{
				CountFleets := CountFleets + 1
			}
			FleetCount := FleetCount + 1
		}
		       
            
        if (CountFleets = MaxPlayerFleets)
            break
            
        Sleep, 1000
        TimeOut := TimeOut - 1
        
        if (TimeOut <= 0)
        {
            Log(Format("ERROR : timeout after {1} seconds waiting for fleets to be int state {2}. exiting", TimeOut, ImageState), 2)
            return 0
        }
    }
	
    ; fold again right menu
	PopRightMenu(0)	
    
    return 1  
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
        ; click the button to show up the menu
        NovaLeftMouseClick(1700, 510)
        Sleep, 500
        		
        ; wait for eventual unselected economy tab
        if NovaFindClick("buttons\" . TabPage . "_off.png", 30, "w3000 n1", FoundX, FoundY, 1500, 145, 1760, 680)
        {
            Log("Selected " . TabPage . " tab in right menu")
        }
        
        if !NovaFindClick("buttons\" . TabPage . "_on.png", 30, "w3000 n0", FoundX, FoundY, 1500, 145, 1760, 680)
        {
            Log("ERROR : Could not find the " . TabPage . " button, exiting.", 2)
            return 0
        }
        
        ; we found button, that's done
        return 1
        
    }
    else
    {
        Log("Hiding Main right menu ...")
        
        ; click to close teh menu
        NovaEscapeClick()
        
        ; make sure we don't have the menu bar again
        ; For this we check if we find the CEG icon which is behind
        if !NovaFindClick("buttons\ceg.png", 30, "w10000 n0")
        {
            Log("ERROR : Timeout for menu bar to disappear, exceeded 10 seconds.", 2)
            return 0
        }
        
        return 1
    }
}

