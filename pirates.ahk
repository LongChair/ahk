#include globals.ahk
#include utils.ahk

;*******************************************************************************
; FarmPirate : Will try to find a pirate, kill it and collect resource
;*******************************************************************************
FarmPirates(PirateCount)
{
    global Pirates
    global KilledCount
	global StationX, StationY
    
    Ret := 0
	
	if (!ReadjustPosition())
	{
		LOG("ERROR : Failed to recenter position on station, exiting ...")
		goto FarmPirates_End
	}
	
	CurrentX := StationX
	CurrentY := StationY
        
    Log(Format("We have {1} pirate(s) to farm ({2}/{3})", PirateCount, PirateCount, Pirates.Length()))


    ; check if we have avengers
	if (AvengersComing())
	{
		LOG("Avengers detected, Bringing fleets back to dock")
		Ret := 1
		goto FarmPirates_End
	}        
	   
    KilledPirate := 0
	
    Loop
	{
        ; we reached the end of the pirates list, then exit
        if (Pirates.Length() <= 0)
        {
            LOG("No more pirates to kill, exiting...")
            Ret := 1
            Goto FarmPirates_End
        }
        
        ; get the pirate coordinates
        Log(Format("Processing pirate #{1}/{2} ({3} left)...", KilledPirate + 1 , PirateCount, Pirates.Lenght()))
        RefValues := StrSplit(PeekClosestRes(Pirates, CurrentX, CurrentY) , ",")
		
		if (RefValues = "")
		{
			Log("No more pirates to kill, ending farming")
			Ret := 1
			goto FarmPirates_End
		}
		
		ResX := RefValues[2]
		ResY := RefValues[3]

        ; try to kill pirate
        if (!KillPirate(ResX, ResY, Killed, Moved))
        {
            Log(Format("ERROR : failed to kill pirates at ({1}, {2}).", ResX, ResY), 2)
            Goto FarmPirates_End
        }
        
		if (Moved)
		{
			CurrentX := ResX
			CurrentY := ResY
		}
		
        ; check if it's been killed
        if (Killed)
        {
            KilledPirate := KilledPirate + 1
            KilledCount  := KilledCount + 1
            
            if (KilledPirate >= PirateCount)
            {
                LOG(Format("Done with killing {1} pirates, Total={2}", PirateCount, KilledCount))
                Ret := 1
                Goto FarmPirates_End
            }
        }
        
         ; check if we have avengers
        if (AvengersComing())
        {
            LOG("Avengers detected, Bringing fleets back to dock")
            Ret := 1
            goto FarmPirates_End
        }        
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
KillPirate(X,Y, ByRef Killed, ByRef Moved)
{
    global MainWinW, MainWinH
    global Pirates_BlackList
	
    Killed := 0
    Moved := 0
	
     ; go to the ressource position
    Log(Format("Going to kill pirate at ({1:i}, {2:i}) ...", X, Y), 1)
    MapMoveToXY(X, Y)

    ; validate if pirate is to be killed
    if (!ValidatePirate(MainWinW / 2, MainWinH / 2, Valid))
    {
        LOG("ERROR :Pirate Validation failed, exiting", 2)
        return 0
    }
    
    if (!Valid)
    {
        LOG("Pirate is not valid, blacklisting and skipping")
		Pirates_BlackList.insert(Format("PIRATE,{1},{2}", X, Y))
		
		; we need to reclaibrate position
		return ReadjustPosition()
    }
    
    ; Send Fleets there
    OffsetClick := 30
	DeltaX := OffsetClick
	DeltaY := OffsetClick
	
	if (!ClickMenuImage((MainWinW / 2) + DeltaX, (MainWinH / 2) + DeltaY, "buttons\GroupMove.png"))
	{
		Log("ERROR : failed to start group move", 2)
		
		; we need to reclaibrate position
		return ReadjustPosition()
	}
		
    ; Select All Fleets
	LOG("Selecting all fleets ...")
	Loop
	{
		; check if we have the left arrow which means we are ready
		if (NovaFindClick("buttons\fleets_arrow_left.png", 30, "w100 n0", FoundX, FoundY, 860, 450, 900, 520))
			break
			
		; right arrow means we have to click to add them all 
		if (NovaFindClick("buttons\fleets_arrow_right.png", 30, "w100 n0", FoundX, FoundY, 860, 450, 900, 520))
		{
			NovaLeftMouseClick(410,787)
		}
		Else
		{
			Log("ERROR : No fleet arrow was found, exiting.", 2)
			return 1
		}
		
		Sleep, 500
	}
	
    ; Click Ok 
	Log("Validating all fleets ...")
	if (!NovaFindClick("buttons\OKFleets.png", 100, "w5000 n1", FoundX, FoundY,  730, 800, 1020, 920))
	{
		; we didn't find button, but try to click 
        Log("ERROR : failed to click OK to attack, trying direct click.", 2)		
		NovaLeftMouseClick(875, 860)
    }
    
	Moved := 1
	
    ; now Wait for all fleets to be theres
    Log("Waiting for fleets to complete move...")
    if (!WaitForFleetsIdle())
    {
        Log("ERROR : failed to wait for fleets to be idle before attack, exiting.", 2)
        return 0
    }
    
    ; check if we can do the attack just before attacking
    if (!ValidateAttack())
    {
        Log("Attack was not validated, skipping.", 2)
        return 1
    }
    
    ; Click on the pirate
    if (!ClickMenuImage(MainWinW / 2, MainWinH / 2, "buttons\attack.png"))
    {
        Log("ERROR : failed to find attack pirate, exiting.", 2)
        return 0
    }
    
	if (NovaFindClick("buttons\red_continue.png", 50, "w1000 n1"))
	{
		Log("Avengers trigger validation")
	}
		
    ; click attack button
    Log("Selecting Tank...")
    ScrollCount := 0
    while (!NovaFindClick("buttons\Tank.png", 30, "w500 n1"))
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
	
	; we can have an heavy ennemy continue popup
	if (NovaFindClick("buttons\red_continue.png", 50, "w3000 n1"))
	{
		Log("Validating heavy enemy continue")
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
    if NovaFindClick("pirates\valid\Pirate.png", 50, "w1000 n0", FoundX, FoundY, 589, 470, 740, 530)
    {
	    ; we check if it's know to be valid
		Loop, Files, %A_ScriptDir%\images\pirates\invalid\*.png"
		{
			FileName := "pirates\invalid\" . A_LoopFileName
			if (NovaFindClick(FileName, 50, "n0", FoundX, FoundY, 589, 560, 740, 590))
			{
				Log(Format("Invalidating a pirate matching {1}", A_LoopFileName))
				goto ValidatePirate_End
			}
		}
	
		Valid := 1
	}
	else
	{
		if NovaFindClick("pirates\valid\Crystals.png", 50, "w2000 n0", FoundX, FoundY, 589, 470, 740, 530)
		{
			Valid := 1
		}
	}
        
    ; we check if it's know to be valid
    ;Loop, Files, %A_ScriptDir%\images\pirates\valid\pirate_*.png"
    ;{
		;FileName := "pirates\valid\" . A_LoopFileName
        ;if NovaFindClick(FileName, 50, "w100 n0")
		;{
			;Log(Format("Validated a pirate matching {1}", A_LoopFileName))
            ;goto ValidatePirate_End
		;}
    ;}
    
    ; if we come here, then we haven't found any valid
    ;return 0
    
    ; close the popup
ValidatePirate_End:
    NovaEscapeMenu()
    
    return 1
}

;*******************************************************************************
; AvengersComing : Detects if avengers are coming
; return 1 if they are, 0 otherwise
;*******************************************************************************
AvengersComing()
{
	return NovaFindClick("buttons\number_mark.png", 50, "n0", FoundX, FoundY, 650, 870, 785, 1024)
}

;*******************************************************************************
; IsTankFresh : Checks if the tank is fresh enough
;*******************************************************************************
IsTankFresh()
{
	Ret := 0
	
	; Open the fleets tab
    if !PopRightMenu(1, "FLEETS")
    {
        Log("ERROR : failed to popup main menu for fleets. exiting", 2)
        return 0
    }
    
	if (!NovaFindClick("buttons\Tank.png", 50, "w1000 n1", FoundX, FoundY, 780, 185, 1050, 850))
	{
		Log("ERROR : failed to find tank fleet. exiting", 2)
        return 0
	}
	
	if (!NovaFindClick("buttons\Tank_popup.png", 50, "w5000 n0"))
	{
		Log("ERROR : failed to find tank popup. exiting", 2)
        return 0
	}
    
	Ret := NovaFindClick("buttons\tank_fresh.png", 50, "n0")
	if (Ret)
		LOG("Tank looks fresh enough :)")
	Else
		LOG("Tank doesn't look fresh :/")
	
	NovaEscapeClick()

    ; fold again right menu
	PopRightMenu(0)	
    
    return Ret  
}

;*******************************************************************************
; ValidateAttack : Validate conditions before completing the attack
; basically check that there would be no players (yellow) in the area
;*******************************************************************************
ValidateAttack()
{
    if NovaFindClick("buttons\yellow_fleet.png", 50, "n0", FoundX, FoundY, 750, 400, 1050, 700)
        return 0
        
    return 1
}

