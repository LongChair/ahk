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
	FileName := ""
	
    ; Major Log
    if (Level & 0x1)
		FileLog(Text, A_ScriptDir . "\MajorLog.txt")
        
    ; Error Log
    if (Level & 0x2)
		FileLog(Text, A_ScriptDir . "\ErrorLog.txt")


	FileLog(Text, A_ScriptDir . "\Log.txt")	
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
    if (X2 = -1)
        X2 := MainWinW - 1
    if (Y2 = -1)
        Y2 := MainWinH - 1
    
    W := X2 - X1 + 1
    H := Y2 - Y1 + 1
    
	Opts := "rBlueStacks oTransBlack," . Variation . " Count a" . X1 . "," . Y1 . "," . W . "," . H . " " . Options
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
    
    GrabPath := A_ScriptDir . "\images\grab\" . A_MM . "-" . A_DD
    FullPath := GrabPath . "\" . A_Hour . "-" . A_Min . "-" . A_Sec
    
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
    NovaLeftMouseClick(SaveX, SaveY)
    Sleep, 1000
	
	; now send the full path to save to
    Send, %FullPath%
    Sleep, 1000
	
	; validate by pressing enter
    Send, {Enter}
}