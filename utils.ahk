#include libs\FindClick.ahk

;*******************************************************************************
; NovaMouseMove : Moves the mouse in screen Coords relative to Nova screen
; X, Y are relative to Nova Window
;*******************************************************************************
NovaMouseMove(X,Y)
{
    global
    MouseMove MainWinX + X, MainWinY + Y, 0
}

;*******************************************************************************
; NovaLeftMouseClick : Left click in screen Coords relative to Nova screen
; X, Y are relative to Nova Window
;*******************************************************************************
NovaLeftMouseClick(X,Y)
{
    global
    MouseClick L, MainWinX + X, MainWinY + Y
}

NovaDragMouse(X, Y, SpanX, SpanY)
{
    global

    MouseClickDrag, L, MainWinX + X, MainWinY + Y, MainWinX + X + SpanX, MainWinY + Y + SpanY, 10
    sleep, 2000
}

;*******************************************************************************
; Log : Logs a string into the log file
; Text : text to log
;*******************************************************************************
Log(Text)
{
    global
    FileAppend, %A_Hour%:%A_Min%:%A_Sec% - %Text%`r`n,  %A_ScriptDir%\Log.txt
}

;*******************************************************************************
; MajorLog : Logs a string into the major log file
; Text : text to log
;*******************************************************************************
MajorLog(Text)
{
    global
    FileAppend, %A_Hour%:%A_Min%:%A_Sec% - %Text%`r`n,  %A_ScriptDir%\MajorLog.txt
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
    global
    
    if (X2 = -1)
        X2 := MainWinW - 1
    if (Y2 = -1)
        Y2 := MainWinH - 1
    
    W := X2 - X1 + 1
    H := Y2 - Y1 + 1
    
	Opts := "rBlueStacks oTransBlack," . Variation . " Count a" . X1 . "," . Y1 . "," . W . "," . H . " " . Options
    FullPath = %A_ScriptDir%\images\%FileName%
    
	return FindClick(FullPath, Opts, FoundX, FoundY)
}

;*******************************************************************************
; FindImage : Find an image into the window
; Filename : File Path realtive to  %A_ScriptDir%
; X1, Y1, X2, Y2 : Coordinates of the region to look in in window coordinates
; FoundX, FoundY : Coordinates of the point found
;*******************************************************************************
FindImage(FileName, X1, Y1, X2, Y2, ByRef FoundX :=0, ByRef FoundY :=0, Variation := 0)
{
    global
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
    global
	local found = 0
    local Remaining := Timeout
	
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
    global
	local found = 1
    local Remaining := Timeout
	
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
    global
    local GrabPath, FullPath
    GrabPath =  %A_ScriptDir%\images\grab\%A_MM%-%A_DD%
    FullPath =  %A_ScriptDir%\%A_Hour%-%A_Min%-%A_Sec%
    
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
    SendRaw, %FullPath%
    Sleep, 1000
	
	; validate by pressing enter
    Send, {Enter}
}