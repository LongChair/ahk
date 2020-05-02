#include globals.ahk
#include utils.ahk
#include pirates.ahk



;Pirates := FindClick("C:\Perso\GitHub\LongChair\ahk\images\ee.png", "e")
;sleep, 1000

;FarmPirates_v2()

;*******************************************************************************
; FarmPirates_v2 : Will try to find a pirate, kill it and collect resource
;*******************************************************************************
FarmPirates_v2()
{
    global FleetPosX, FleetPosY
    global MaxPlayerFleets
    
    FleetsSpan := Object( 1, 3, 4, 6)
    FleetAvailable := []
    
    for StartFleet, EndFleet in FleetsSpan
    {
       
        ; Open the fleets tab
        if !PopRightMenu(1, "FLEETS")
        {
            Log("ERROR : failed to popup main menu for fleets. exiting", 2)
            return 0
        }
        
        ; check the fleets status
        Log(Format("Checking available fleets for {1} to {2} ...",StartFleet, EndFleet))
        StrStatus := "Fleets available : "
        for iFleet in range(StartFleet, EndFleet, 1)
        {
           GetFleetArea(iFleet, X1, Y1, X2, Y2)
           
           if NovaFindClick("buttons\manage_button.png", 70, "n0", FoundX, FoundY, X1, Y1, X2, Y2)
           {
                FleetAvailable[iFleet] := 
                StrStatus := Format("{1} {2}}", strStatus, iFleet)
           }
           Else
           {
                if NovaFindClick("buttons\recall_button.png", 70, "n0", FoundX, FoundY, X1, Y1, X2, Y2)
                {
                    FleetAvailable[iFleet] := 1
                    StrStatus := Format("{1} {2}}", strStatus, iFleet)
                }
                else
                {
                    FleetAvailable[iFleet] := 0
                }
           }
        }
        Log(StrStatus)
        
        
        ; click the startfleet
         LOG(Format("Switching to Fleet {1} system ...",StartFleet))
        GetFleetArea(StartFleet, X1, Y1, X2, Y2)
        NovaLeftMouseClick((X1+X2)/2, (Y1+Y2)/2)
						
		; click the "Voir" Menu
        if (!NovaFindClick("buttons\voir.png", 50, "w2000 n1"))
        {
            Log("ERROR : failed to find the Voir button. exiting", 2)
            return 0
        }
        
        ; wait for screen system to be leaoded
        if (!WaitNovaScreen("SYSTEME", 30))
        {
            Log("ERROR : failed wait for system screen. exiting", 2)
            return 0
        }
        
        ; we are zoomed on fleet, click the back Button
        if (!NovaFindClick("buttons\back.png", 50, "w2000 n1"))
        {
            Log("ERROR : failed to find the back button. exiting", 2)
            return 0
        }
        
        ; scan system 
        Pirates := NovaFindClickAll("pirates\pirate3d.png", 20)
        
        CoordsArray := StrSplit(Pirates, "`n")

        PirateList := []
        Loop % CoordsArray.MaxIndex()
        {
           PirateList.Insert(Format("PIRATE,{1}", CoordsArray[A_Index]))
        }
        
        for iFleet in range(StartFleet, EndFleet, 1)
        {
        
            if (FleetAvailable[iFleet])
            {
                if (PirateList.Length() <= 0)
                {
                    LOG("No more pirates to kill, exiting...")
                    Ret := 1
                    Goto FarmPirates_v2_Killing_Done
                }

                FleetX := FleetPosX[iFleet]
                FleetY := FleetPosY[iFleet]

                PiratesCoords := StrSplit(PeekClosestRes(PirateList, FleetX, FleetY) , ",")

                PirateX := PiratesCoords[2]
                PirateY := PiratesCoords[3]

                Log(Format("Closest pirates to fleet {1} at ({2}, {3}) is at ({4}, {5})", iFleet, FleetX, FleetY, PirateX, PirateY))
                
                ; Click Pirate
                NovaLeftMouseClick(PirateX, PirateY)
                
                ; Validate it's a pirate
                if (!ValidatePirate(WinCenterX, WinCenterY, Valid))
                {
                    NovaEscapeClick()
                    LOG("ERROR :Pirate Validation failed, exiting", 2)
                    return 0
                }
        
                if (!Valid)
                {
                    LOG("Pirate is not valid, skipping")
                    NovaEscapeClick()                
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
                
                ; Select the proper fleet
                Log(Format("Attacking pirate with Fleet {1}", iFleet))
                GetAttackFleetArea(iFleet, X1, Y1, X2, Y2)
                NovaLeftMouseClick((X1+X2)/2, (Y1+Y2)/2)
                
                FleetPosX[iFleet] := PirateX
                FleetPosY[iFleet] := PirateY
            }
        }
        
        FarmPirates_v2_Killing_Done:
        
    }
    
    return 1
}