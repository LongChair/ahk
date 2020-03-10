#include globals.ahk
#include utils.ahk


;*******************************************************************************
; FarmElites : Will try to find elites in a gvien system and kill them
;*******************************************************************************
FarmElites()
{
    global StationX, StationY
    global MainWinW, MainWinH
    
    Ret := 0
    
    if (!GotoScreen("SYSTEME", 60))
    {
        Log("ERROR : failed to go to system screen, exiting.", 2)
        return 0
    }
	    
    Loop
	{
        
        ; Centers on station
        if (!ReadjustPosition())
        {
            LOG("ERROR : Failed to recenter position on station, exiting ...")
            goto FarmElites_End
        }
        
               
        ; try to find elite
		if (NovaFindClick("buttons\Elite.png", 30, "w100 n0", FoundX, FoundY, 860, 450, 950, 550))
        {
        
            ; Click on the pirate
            if (!ClickMenuImage(MainWinW / 2, MainWinH / 2 + 10 , "buttons\groupattack.png"))
            {
                Log("ERROR : failed to find click group attack, exiting.", 2)
                return 0
            }
            
            ; eventually acknowledge avengers
            if (NovaFindClick("buttons\red_continue.png", 50, "w1000 n1"))
            {
                Log("Avengers trigger validation")
            }
		
        
            ; make sure we start the move
            Sleep 3000
            

            ; now Wait for all fleets to be there
            Log("Waiting for fleets to complete move...")
            if (!WaitForFleetsIdle(60))
            {
                Log("ERROR : failed to wait for fleets to be idle before attack, exiting.", 2)
                Ret := 0
                goto FarmElites_End
            }            
            
            ; recall all the fleets
            if (!RecallAllFleets())
            {
                Log("ERROR : failed to recall fleets to station", 2)
                Ret := 0
                goto FarmElites_End
            }
                            
        }
        Else
        {   
            Sleep 10000
        }       

    }

FarmElites_End:
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
	MapMoveToXY(X, Y - 20)
	
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
    OffsetClick := 35
	DeltaX := OffsetClick
	DeltaY := -OffsetClick
	
	random, rnd, 0.0, 2.0 
	if (rnd < 1.0)
	{
		DeltaX := -DeltaX
	}
	
	;random, rnd, 0.0, 2.0 
	;if (rnd < 1.0)
	;{
	;	DeltaY := -DeltaY
	;}

	
	if (!ClickMenuImage((MainWinW / 2) + DeltaX, (MainWinH / 2) + DeltaY + 10 , "buttons\GroupMove.png"))
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
		if (NovaFindClick("buttons\fleets_arrow_left.png", 30, "w100 n0", FoundX, FoundY, 860, 450, 950, 550))
			break
		Else
		{
			; or it could be double arrow if one fleet is busy
			if (NovaFindClick("buttons\fleets_arrow_left_right.png", 30, "w100 n0", FoundX, FoundY, 860, 430, 950, 550))
				break
		}
			
			
		; right arrow means we have to click to add them all 
		if (NovaFindClick("buttons\fleets_arrow_right.png", 30, "w100 n0", FoundX, FoundY, 860, 450, 950, 550))
		{
			NovaLeftMouseClick(422,825)
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
	if (!NovaFindClick("buttons\OKFleets.png", 100, "w5000 n1", FoundX, FoundY,  830, 800, 1020, 920))
	{
		; we didn't find button, but try to click 
        Log("ERROR : failed to click OK to attack, trying direct click.", 2)		
		NovaLeftMouseClick(920, 893)
    }

	; wait for move to start 
    Log("Waiting for fleets to start move...")
    if (!WaitForFleetsMoving())
    {
        Log("ERROR : failed to wait for fleets to be start move, exiting.", 2)
        return 0
    }

	Moved := 1

    ; now Wait for all fleets to be theres
    Log("Waiting for fleets to complete move...")
    if (!WaitForFleetsIdle(60))
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
    if (!ClickMenuImage(MainWinW / 2, MainWinH / 2 + 10 , "buttons\attack.png"))
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
    while (!NovaFindClick("buttons\Tankfleet.png", 50, "w500 n1"))
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
    if (!WaitForFleetsIdle(10))
    {
        Log("ERROR : failed to wait for fleets to be idle after attack, exiting.", 2)
        return 0
    }
    
    Killed := 1
    return 1
}


;*******************************************************************************
; FarmPiratesMulti : Will try to find a pirate & kill it with multiples fleets
;*******************************************************************************
FarmPiratesMulti(PirateCount)
{
    global Pirates
    global KilledCount
	global StationX, StationY
	global FleetPosX, FleetPosY
    
    Ret := 0
	
	
	if (!ReadjustPosition())
	{
		LOG("ERROR : Failed to recenter position on station, exiting ...")
		goto FarmPiratesMulti_End
	}
	
	; we reset fleets position to station position
	Loop, %MaxPlayerFleets%
	{
		FleetPosX[A_Index] := StationX
		FleetPosY[A_Index] := StationY
	}
        
    Log(Format("We have {1} pirate(s) to farm ({2}/{3})", PirateCount, PirateCount, Pirates.Length()))

	   
    KilledPirate := 0
	AvailFleet := 0
	
    Loop
	{
        ; we reached the end of the pirates list, then exit
        if (Pirates.Length() <= 0)
        {
            LOG("No more pirates to kill, exiting...")
            Ret := 1
            Goto FarmPiratesMulti_End
        }
        
		; get first available fleet
		
		;if (!AvailFleet)
		;{
		;	AvailFleet := GetFirstIdleFleet(200)
			 
		;	if (!AvailFleet)
		;	{
		;		Log("ERROR : failed to wait for an available fleet, exiting")
		;		Ret := 0
		;		Goto FarmPiratesMulti_End
		;	}
		;}
		
		;Log(Format("Fleet #{1} is available...", AvailFleet))
		CurrentX  := StationX
		CurrentY  := StationY
		
        ; get the pirate coordinates
        Log(Format("Processing pirate #{1}/{2} ({3} left)...", KilledPirate + 1 , PirateCount, Pirates.Length()))
        RefValues := StrSplit(PeekClosestRes(Pirates, CurrentX, CurrentY) , ",")
		
		if (RefValues = "")
		{
			Log("No more pirates to kill, ending farming")
			Ret := 1
			goto FarmPiratesMulti_End
		}
		
		ResX := RefValues[2]
		ResY := RefValues[3]

        ; try to kill pirate
        if (!KillPirateMulti(ResX, ResY, AvailFleet, Killed))
        {
            Log(Format("ERROR : failed to kill pirates at ({1}, {2}).", ResX, ResY), 2)
            Goto FarmPiratesMulti_End
        }
        		
        ; check if it's been killed
        if (Killed)
        {
		
			AvailFleet := 0
			
			FleetPosX[AvailFleet] := ResX
			FleetPosY[AvailFleet] := ResY
			
            KilledPirate := KilledPirate + 1
            KilledCount  := KilledCount + 1
            
            if (KilledPirate >= PirateCount)
            {
                LOG(Format("Done with killing {1} pirates, Total={2}", PirateCount, KilledCount))
                Ret := 1
                Goto FarmPiratesMulti_End
            }
        }
        
    }
    
FarmPiratesMulti_End:

	if (!WaitForFleetsIdle(60))
    {
        Log("ERROR : failed to wait for fleets to be idle before recalling, exiting.", 2)
    }
	
    ; Recall fleets to station
    if (!RecallAllFleets())
    {
        Log("ERROR : failed to recall fleets to station", 2)
        return 0
    }
        
    return Ret
}

;*******************************************************************************
; KillPirateMulti : kill a pirate in multi Mode
;*******************************************************************************
KillPirateMulti(X,Y, Fleet, ByRef Killed)
{
    global MainWinW, MainWinH
    global Pirates_BlackList
	
    Killed := 0

	
     ; go to the ressource position
    Log(Format("Going to kill pirate at ({1:i}, {2:i}) ...", X, Y), 1)
	MapMoveToXY(X, Y)
	
	;click on the pirate
	NovaLeftMouseClick(WinCenterX, WinCenterY)
	
    ; validate if pirate is to be killed
    if (!ValidatePirate(WinCenterX, WinCenterY, Valid))
    {
		NovaEscapeClick()
        LOG("ERROR :Pirate Validation failed, exiting", 2)
        return 0
    }
    
    if (!Valid)
    {
		
        LOG("Pirate is not valid, blacklisting and skipping")
		Pirates_BlackList.insert(Format("PIRATE,{1},{2}", X, Y))
		
		NovaEscapeClick()
		
		; we need to reclaibrate position
		return ReadjustPosition()
    }
   
    ; attack the pirate
	if (!NovaFindClick("buttons\attack.png", 50, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
    {
        LOG("ERROR : Could Not find the menu image for attack, different menu popped up ?", 2)
        return 0
    }
	
    
	if (NovaFindClick("buttons\red_continue.png", 50, "w1000 n1"))
	{
		Log("Avengers trigger validation")
	}
		
	
	Count := 0
Pick_Fleet:	
	Picked := 0
	
	if NovaFindClick("buttons\attack_dock.png", 70, "n1", FoundX, FoundY, 950, 160, 1140, 900)
	{
		Picked := 1
	}
	else 
	{
		if NovaFindClick("buttons\attack_wait.png", 70, "n1", FoundX, FoundY, 950, 160, 1140, 900)
		{
			Picked := 1
		}
	}
	
	if !Picked
	{
		Sleep, 1000
		Count := Count  + 1 
		
		if Count >= 120
		{
			LOG("ERROR : Timeout waiting to pick fleet, exiting")
			return 0
		}
		
		goto Pick_Fleet
	}
	
	; we can have an heavy ennemy continue popup
	if (NovaFindClick("buttons\red_continue.png", 50, "w1000 n1"))
	{
		Log("Validating heavy enemy continue")
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
    ; now check if it's valid 
    
    ; we check if it's a pirate
    if NovaFindClick("pirates\valid\Pirate.png", 50, "w1000 n0", FoundX, FoundY, 600, 470, 780, 540)
    {
	    ; we check if it's know to be valid
		Loop, Files, %A_ScriptDir%\images\pirates\invalid\*.png"
		{
			FileName := "pirates\invalid\" . A_LoopFileName
			if (NovaFindClick(FileName, 50, "n0", FoundX, FoundY, 600, 560, 780, 620))
			{
				Log(Format("Invalidating a pirate matching {1}", A_LoopFileName))
				goto ValidatePirate_End
			}
		}
	
		Valid := 1
	}
	else 
	{
		if (NovaFindClick("buttons\attack.png", 50, "w2000 n0", FoundX, FoundY, 500,175, 1600, 875))
		{			
			if NovaFindClick("pirates\valid\Crystals.png", 50, "w1000 n0", FoundX, FoundY, 600, 470, 780, 540)
			{
				Valid := 1
			}
			else if NovaFindClick("pirates\valid\Minerals.png", 50, "w1000 n0", FoundX, FoundY, 600, 470, 780, 540)
			{
				Valid := 1
			}
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


;*******************************************************************************
; FarmPirates3D : Farms the pirates in 3D mode
;*******************************************************************************
FarmPirates3D(PirateCount)
{
	global FleetX, FleetY
	global KilledPirate, Pirates
	
	; goes to system screen
	if (!GotoScreen("SYSTEME", 10))
	{
		return 0
	}
	
	Sleep ,3000
	
	Pirates    := []
	
	NovaFindClick("pirates\pirate3d.png", 80, "e n0 FuncHandlePirate", FoundX, FoundY, 340, 160, 1460, 820)
	
	if (!NovaFindClick("buttons\station3d.png", 50, "w100 n0", FleetX, FleetY, 340, 160, 1460, 820))
	{
		FleetX := 0
		FleetY := 0
	}

	KilledPirate := 0
	Loop
	{
		
		Log(Format("Fleet found at {1}, {2} ", FleetX, FleetY))
		
		  ; we reached the end of the pirates list, then exit
        if (Pirates.Length() <= 0)
        {
            LOG("No more pirates to kill, exiting...")
            Ret := 1
            Goto FarmPirates3D_End
        }
        
        ; get the pirate coordinates
        Log(Format("Processing pirate #{1}/{2} ({3} left)...", KilledPirate + 1 , PirateCount, Pirates.Lenght()))
        RefValues := StrSplit(PeekClosestRes(Pirates, FleetX, FleetY) , ",")
		
		if (RefValues = "")
		{
			Log("No more pirates to kill, ending farming")
			Ret := 1
			goto FarmPirates3D_End
		}
		
		PirateX := RefValues[2]
		PirateY := RefValues[3]
		
		
		Log(Format("Closest Pirate to {1}, {2} we found is at {3}, {4}", FleetX, FleetY, PirateX, PirateY))
		
		Killed := 0
		Moved := 0
		if (!KillPirateOnScreen(PirateX, PirateY, Killed, Moved))
		{
			LOG("ERROR : Pirate Kill failed, exiting", 2)
			Ret := 0
            Goto FarmPirates3D_End
		}
		
		
		if (Killed)
        {
            KilledPirate := KilledPirate + 1
            KilledCount  := KilledCount + 1
            
            if (KilledPirate >= PirateCount)
            {
                LOG(Format("Done with killing {1} pirates, Total={2}", PirateCount, KilledCount))
                Ret := 1
                Goto FarmPirates3D_End
            }
        }
		
		if (Moved)
		{
			FleetX := PirateX
			FleetX := PirateY
		}

	}
	
	FarmPirates3D_End:
	return Ret

}

;*******************************************************************************
; HandlePirate : Handle Found Pirate
;*******************************************************************************
HandlePirate(X, Y)
{
	global FleetX, FleetY
	global PirateX, PirateY
	
	Pirates.Insert(Format("{1},{2:i},{3:i}", "PIRATE", X, Y))	
}


;*******************************************************************************
; KillPirateOnScreen : Kiills the pirate at center of screen
;*******************************************************************************
KillPirateOnScreen(X, Y, ByRef Killed, ByRef Moved)
{
    global MainWinW, MainWinH
    global Pirates_BlackList
	
    Killed := 0
    Moved := 0
	
	 ; validate if pirate is to be killed
    if (!ValidatePirate(X, Y, Valid))
    {
        LOG("ERROR :Pirate Validation failed, exiting", 2)
        return 0
    }
    
    if (!Valid)
    {
        LOG("Pirate is not valid, blacklisting and skipping")
		Pirates_BlackList.insert(Format("PIRATE,{1},{2}", X, Y))
		
		Ret := 1
		goto BackAndEnd
    }
	
    
    ; Send Fleets there
    OffsetClick := 80
	DeltaX := OffsetClick
	DeltaY := OffsetClick
	
			
	
	if (!ClickMenuImage((MainWinW / 2) + DeltaX, (MainWinH / 2) + DeltaY, "buttons\GroupMove.png"))
	{
		Log("ERROR : failed to start group move", 2)
		
		Ret := 1
		goto BackAndEnd
	}
		
    ; Select All Fleets
	LOG("Selecting all fleets ...")
	Loop
	{
		; check if we have the left arrow which means we are ready
		if (NovaFindClick("buttons\fleets_arrow_left.png", 30, "w100 n0", FoundX, FoundY, 860, 450, 900, 520))
			break
		Else
		{
			; or it could be double arrow if one fleet is busy
			if (NovaFindClick("buttons\fleets_arrow_left_right.png", 30, "w100 n0", FoundX, FoundY, 860, 430, 900, 550))
				break
		}
			
			
		; right arrow means we have to click to add them all 
		if (NovaFindClick("buttons\fleets_arrow_right.png", 30, "w100 n0", FoundX, FoundY, 860, 450, 900, 520))
		{
			NovaLeftMouseClick(410,787)
		}
		Else
		{
			Log("ERROR : No fleet arrow was found, exiting.", 2)
			Ret := 1
			goto BackAndEnd
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

	; wait for move to start 
    Log("Waiting for fleets to start move...")
    if (!WaitForFleetsMoving())
    {
        Log("ERROR : failed to wait for fleets to be start move, exiting.", 2)
        Ret := 0
		goto BackAndEnd
    }

	Moved := 1

    ; now Wait for all fleets to be theres
    Log("Waiting for fleets to complete move...")
    if (!WaitForFleetsIdle(60))
    {
        Log("ERROR : failed to wait for fleets to be idle before attack, exiting.", 2)
        Ret := 0
		goto BackAndEnd
    }
    
 
    ; Click on the pirate
    if (!ClickMenuImage(X, y, "buttons\attack.png"))
    {
        Log("ERROR : failed to find attack pirate, exiting.", 2)
        Ret := 0
		goto BackAndEnd
    }
    
	if (NovaFindClick("buttons\red_continue.png", 50, "w1000 n1"))
	{
		Log("Avengers trigger validation")
	}
		
    ; click attack button
    Log("Selecting Tank...")
    ScrollCount := 0
    while (!NovaFindClick("buttons\Tankfleet.png", 50, "w500 n1"))
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
    if (!WaitForFleetsIdle(10))
    {
        Log("ERROR : failed to wait for fleets to be idle after attack, exiting.", 2)
        return 0
    }
    
	Ret := 1
	Killed := 1

BackAndEnd:

	while NovaFindClick("buttons\back_arrow.png", 30, "w100 n1", FoundX, FoundY, 0, 40, 200, 140)
	{
		LOG("Clicking on back button")
	}
	
    return Ret
}