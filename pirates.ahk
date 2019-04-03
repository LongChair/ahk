#include globals.ahk
#include utils.ahk

;*******************************************************************************
; FarmPirate : Will try to find a pirate, kill it and collect resource
;*******************************************************************************
FarmPirates(PirateCount)
{
    global Pirates
    global KilledCount
    
    Ret := 0
    
    ; Go to current system
    if !GotoSystem("")
    {
        return 0
    }
    
    ; then go in 2D Mode
    if !Toggle2DMode()
    {
        Log("ERROR : Failed to toggle 2D mode, exiting.", 2)
        return 0
    }
        
    Log(Format("We have {1} pirate(s) to farm ({2}/{3})", PirateCount, PirateCount, Pirates.Length()))

    MapPosX := 0
	MapPosY := 0
    
    CurrentPirate := 1
    KilledPirate := 0
    Loop
	{
        ; we reached the end of the pirates list, then exit
        if (CurrentPirate >= Pirates.Length())
        {
            LOG("No more pirates to kill, exiting...")
            Ret := 1
            Goto FarmPirates_End
        }
        
        ; get the pirate coordinates
        Log(Format("Processing pirate #{1}/{2}...", KilledPirate + 1 , PirateCount))
        RefValues := StrSplit(Pirates[CurrentPirate], ",")
		ResX := RefValues[2]
		ResY := RefValues[3]

        ; try to kill pirate
        if (!KillPirate(ResX, ResY, Killed))
        {
            Log(Format("ERROR : failed to kill pirates at ({1}, {2}).", ResX, ResY), 2)
            Goto FarmPirates_End
        }
        
        ; check if it's been killed
        if (Killed)
        {
            KilledPirate := KilledPirate + 1
            KilledCount  := KilledCount + 1
            
            if (KilledPirate >= PirateCount)
            {
                LOG(Format("Done with killing {1} pirates, Total={2}]", PirateCount, KilledCount))
                Ret := 1
                Goto FarmPirates_End
            }
        }
        
        CurrentPirate := CurrentPirate + 1
        
    }
    
FarmPirates_End:
    ; Recall fleets to station
    if (!RecallAllFleets())
    {
        Log("ERROR : failed to recall fleets to station", 2)
        return 0
    }
        
    return Ret
}

;*******************************************************************************
; FarmPirate : Will try to find a pirate, kill it and collect resource
; Function assumes we're in the system center in 2D as startpoint
;*******************************************************************************
KillPirate(X,Y, ByRef Killed)
{
    global MainWinW, MainWinH
    
    Killed := 0
    
     ; go to the ressource position
    Log(Format("Going to kill pirate at ({1:i}, {2:i} ...", X, Y), 1)
    MapMoveToXY(X, Y)

    ; validate if pirate is to be killed
    if (!ValidatePirate(MainWinW / 2, MainWinH / 2, Valid))
    {
        LOG("ERROR :Pirate Validation failed, exiting", 2)
        return 0
    }
    
    if (!Valid)
    {
        LOG("Pirate is not valid, skipping")
        return 1
    }
    
    ; Send Fleets there
    OffsetClick := 30
    Count := 0
	Loop
	{
		if (Count = 0)
        {
            DeltaX := OffsetClick
            DeltaY := OffsetClick
        }
			
		if (Count = 1)
        {
            DeltaX := -OffsetClick
            DeltaY := OffsetClick
        }
			
		if (Count = 2)        
        {
            DeltaX := OffsetClick
            DeltaY := -OffsetClick
        }
			
		if (Count = 3)
        {
            DeltaX := -OffsetClick
            DeltaY := -OffsetClick
        }

        NovaLeftMouseClick(MainWinW / 2 + DeltaX, MainWinH / 2 + DeltaY)
			
		Sleep, 1000
		
		; click group move
		if !NovaFindClick("buttons\GroupMove.png", 50, "w2000 n1")
		{
            ; we clicked on something else, make sure there is no popup
			NovaEscapeClick()
			Sleep, 1000
            
            ; Now recenter on pirate and close popup
            NovaLeftMouseClick(MainWinW / 2 - DeltaX, MainWinH / 2 - DeltaY)
            NovaEscapeClick()
			Sleep, 1000
                        
			Count := Count + 1
			
			if (Count = 4)	
			{
				Log("ERROR : failed to select group move on fleets, exiting.", 2)
				return 0
			}
		}
		Else
		{
			break
		}
	}
    
    ; Select All Fleets
    if !NovaFindClick("buttons\AllFleets.png", 50, "w2000 n1")
    {
        Log("ERROR : failed to select all fleets, exiting.", 2)
        return 0
    }
	
    ; Click Ok 
    if !NovaFindClick("buttons\OKFleets.png", 50, "w2000 n1")
    {
        Log("ERROR : failed to select all fleets, exiting.", 2)
        return 0
    }
    
    ; now Wait for all fleets to be there
	Sleep, 1000
    Log("Waiting for fleets to complete move...")
    if (!WaitForFleetsIdle())
    {
        Log("ERROR : failed to wait for fleets to be idle before attack, exiting.", 2)
        return 0
    }
    
    ; Click on the pirate
    NovaLeftMouseClick(MainWinW / 2, MainWinH / 2)
    
    ; click attack button
    Log("Attacking it ...")
    if !NovaFindClick("buttons\attack.png", 70, "w2000 n1")
    {
        Log("ERROR : failed to find attack button, exiting.", 2)
        return 0
    }
    
    ; click attack button
    Log("Selecting Tank...")
    ScrollCount := 0
    while (!NovaFindClick("buttons\Tank.png", 70, "w1000 n1"))
    {
        NovaMouseMove(1050, 470)
        MouseClick, WheelDown,,, 2
        Sleep 1000
    
        ScrollCount := ScrollCount + 1
        
        ; if we didn't fin the tank, just exit
        if (ScrollCount >= 2)
        {
            Log("ERROR : failed to find tank fleet exiting.", 2)
            return 0
        }
    }
    
    ; now Wait for all fleets to be out of fight
    Log("Waiting for fleets to complete attack...")
    if (!WaitForFleetsIdle())
    {
        Log("ERROR : failed to wait for fleets to be idle after attack, exiting.", 2)
        return 0
    }
    
    Killed := 1
    return 1
}

;*******************************************************************************
; ValidatePirate : Validate if the pirate is to be killed
; return 1 if pirate is valid, 0 otherwise
;*******************************************************************************
ValidatePirate(X, Y, ByRef Valid)
{
    Valid := 0
    
     ; Click on the pirate
    NovaLeftMouseClick(X, Y)
    
    ; now check if it's valid 
    
    ; we check if it's a pirate
    if !NovaFindClick("pirates\valid\Pirate.png", 50, "w2000 n0")
        return 0
        
    ; we check if it's know to be valid
    Loop, Files, %A_ScriptDir%\images\pirates\valid\pirate_*.png"
    {
		FileName := "pirates\valid\" . A_LoopFileName
        if NovaFindClick(FileName, 50, "w100 n0")
		{
			Log(Format("Validated a pirate matching {1}", A_LoopFileName))
            goto ValidatePirate_End
		}
    }
    
    ; if we come here, then we haven't found any valid
    return 0
    
    ; close the popup
ValidatePirate_End:
    NovaEscapeClick()
    Valid := 1
    
    return 1
}