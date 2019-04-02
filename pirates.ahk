#include globals.ahk
#include utils.ahk

;*******************************************************************************
; FarmPirate : Will try to find a pirate, kill it and collect resource
;*******************************************************************************
FarmPirates(PirateCount)
{
    global Pirates

    Log("Not Yet Implemented")
    return 1
    
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
    
    ; cap the amount of pirates to kill
    if (Pirates.Length() < PirateCount)
        PirateCount := Pirates.Length()
     
    Log(Format("We have {1} pirate(s) to farm ({2}/{3})", PirateCount, PirateCount, Pirates.Length()))

    ; Recall all mecas
    if (!RecallSomeMecas(MaxPlayerMecas))
    {
        Log("ERROR : Failed to recall all mecas, exiting.", 2)
        return 0
    }
     
    MapPosX := 0
	MapPosY := 0
    
    CurrentPirate := 1
    Loop, % PirateCount
	{
        Log(Format("Processing pirate #{1}/{2}...", CurrentPirate, PirateCount))
        RefValues := StrSplit(Pirates[CurrentPirate], ",")
		ResX := RefValues[2]
		ResY := RefValues[3]
        
        
        if (!KillPirate(ResX, ResY))
        {
            Log(Format("ERROR : failed to kill pirates at ({1}, {2}).", ResX, ResY), 2)
            return 0
        }
        
        if (!CollectPirateRessource(MainWinW / 2 ,  MainWinH / 2))
        {
        
            Log(Format("ERROR : failed to collect pirates ressource at ({1}, {2}).",  MainWinW / 2,  MainWinH / 2), 2)
            return 0
        }
        
        CurrentPirate := CurrentPirate + 1
    }
    
    ; Recall fleets to station
    if (!RecallAllFleets())
    {
        Log("ERROR : failed to recall fleets to station", 2)
        return 0
    }
        
    return 1
}

;*******************************************************************************
; FarmPirate : Will try to find a pirate, kill it and collect resource
; Function assumes we're in the system center in 2D as startpoint
;*******************************************************************************
KillPirate(X,Y)
{
    global MainWinW, MainWinH
    
     ; go to the ressource position
    Log(Format("Going to kill pirate at ({1:i}, {2:i} ...", X, Y), 1)
    MapMoveToXY(X, Y)

    ; Send Fleets there
    OffsetClickX := -100
    OffsetClickY := -100
    NovaLeftMouseClick(MainWinW / 2 - OffsetClickX, MainWinH / 2 - OffsetClickY)
    
    ; click group move
    if !NovaFindClick("buttons\GroupeMove.png", 70, "w2000 n1")
    {
        Log("ERROR : failed to find Send fleets, exiting.", 2)
        return 0
    }
    
    ; Select All Fleets
    if !NovaFindClick("buttons\AllFleets.png", 70, "w2000 n1")
    {
        Log("ERROR : failed to select all fleets, exiting.", 2)
        return 0
    }
    
    ; Click Ok 
    if !NovaFindClick("buttons\OKFleets.png", 70, "w2000 n1")
    {
        Log("ERROR : failed to select all fleets, exiting.", 2)
        return 0
    }
    
    ; now Wait for all fleets to be there
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
    while (!NovaFindClick("buttons\Tank.png", 70, "w2000 n1"))
    {
        NovaMouseMove(1050, 470)
        MouseClick, WheelDown,,, 2
        Sleep 2000
    
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
    
    return 1
}

;*******************************************************************************
; CollectPirateRessource : Collects a ressource around X, Y area
;*******************************************************************************
CollectPirateRessource(X, Y)
{
    MarginX := 200
    MarginY := 200
    
    Loop 
    {
        ; wait to have a free meca
        Log("Waiting for a free meca ...")
        Loop
        {
            GetAvailableMecaCount(NumMecas)
            
            if (NumMecas)
            {
                break
            }
            Else
            {
                Sleep, 5000
            }
        }
        
        ; look for ressource
        Log("Looking for ressource...")
        if NovaFindClick("resources\pirate.png", 70, "w2000 n1", FoundX, FoundY, X - MarginX,  Y - MarginY, X + MarginX,  Y + MarginY)
        {
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
            
        }
        Else
        {
            Log("Looks like there is nothing left to collect, exiting collection ...")
            return 1
        }
        
    }

}