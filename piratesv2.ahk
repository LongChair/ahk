#include globals.ahk
#include utils.ahk
#include pirates.ahk


;*******************************************************************************
; FarmPirates_v2 : Will try to find a pirate, kill it and collect resource
;*******************************************************************************
FarmPirates_v2(FleetsSpan)
{
    global FleetPosX, FleetPosY
    global MaxPlayerFleets, Window_ID
	global WinCenterX, WinCenterY
    global KilledCount
	global MapPosX, MapPosY
	
    FleetAvailable := []
    KilledList := []
	
	for StartFleet, EndFleet in FleetsSpan
	{
	
	    ; Go to the proper system
	    if (!GoToFavorite(A_Index))
		{
			Log(Format("ERROR : failed to favorite {1}. exiting", A_Index), 2)
			return 0
		}


		; Scan the current system
		MapPosX := 0
		MapPosY := 0
		
		FarmingMulti := 1
		Pirates    := []
		ScanMap(Format("FarmSystem{1}", A_Index))
		SortResList(Pirates)
		LOG(Format("We have now {1} Pirates found.", Pirates.Length()))		
		
		; Open the fleets tab
		if !PopRightMenu(1, "FLEETS")
		{
			Log("ERROR : failed to popup main menu for fleets. exiting", 2)
			return 0
		}
		
		; check the fleets status
		Log(Format("Checking available fleets for {1} to {2} ...",StartFleet, EndFleet))
		StrStatus := "Fleets available : "
		for iFleet in range(StartFleet, EndFleet + 1, 1)
		{
		   GetFleetArea(iFleet, X1, Y1, X2, Y2)
		   
		   if NovaFindClick("buttons\recall_button.png", 70, "n0", FoundX, FoundY, X1, Y1, X2, Y2)
		   {
				FleetAvailable[iFleet] := 1
				StrStatus := Format("{1} {2}", strStatus, iFleet)
		   }
		   Else
		   {
				if NovaFindClick("buttons\manage_button.png", 70, "n0", FoundX, FoundY, X1, Y1, X2, Y2)
				{
					FleetAvailable[iFleet] := 1
					StrStatus := Format("{1} {2}", strStatus, iFleet)
				}
				else
				{
					FleetAvailable[iFleet] := 0
				}
		   }
		}
		
		PopRightMenu(0)
		Log(StrStatus)

		for iFleet in range(StartFleet, EndFleet + 1, 1)
		{
			
			if (FleetAvailable[iFleet])
			{
			
FarmPirates_v2_New_Pirate:
				if (Pirates.Length() <= 0)
				{
					LOG("No more pirates to kill, exiting...")
					Ret := 1
					Goto FarmPirates_v2_Killing_Done
				}

				FleetX := FleetPosX[iFleet]
				FleetY := FleetPosY[iFleet]

				PiratesCoords := StrSplit(PeekClosestRes(Pirates, FleetX, FleetY) , ",")

				PirateX := PiratesCoords[2]
				PirateY := PiratesCoords[3]

				Log(Format("Closest pirates to fleet {1} at ({2}, {3}) is at ({4}, {5})", iFleet, FleetX, FleetY, PirateX, PirateY))
				MapMoveToXY(PirateX, PirateY)
				
				if (!NovaFindClick("pirates\pirate.png", 110, "w1000 n1", FoundX, FoundY, 860, 470, 1020, 630))
				{
					LOG("ERROR : Could Not find the pirate for attack, terminating round", 2)
					Goto FarmPirates_v2_Next_group
				}
				
				; Validate it's a pirate
				if (!ValidatePirate(WinCenterX, WinCenterY, Valid))
				{
					NovaEscapeClick()
					LOG("ERROR :Pirate Validation failed, exiting", 2)
					
					Goto FarmPirates_v2_Next_group
				}
		
				if (!Valid)
				{
					LOG("Pirate is not valid, skipping")
					NovaEscapeMenu()
					
					Goto FarmPirates_v2_NextPirate
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
				SaveFleetPosToFile(Format("{1}\{2}-Fleets.ini", A_ScriptDir, PlayerName))
				KilledCount := KilledCount + 1 
				Log(Format("We killed {1} pirates so far", KilledCount))
				
				
FarmPirates_v2_NextPirate:
				
				; Wait a bit 
				Sleep, 1000
			}
		
			FarmPirates_v2_Next_group:
		}
		
		FarmPirates_v2_Killing_Done:
		
	}

    return 1
}



;*******************************************************************************
; RecenterOnSystem : Recenter by clicling on system center
;*******************************************************************************
RecenterOnSystem()
{

			
	if (NovaFindClick("pirates\center_system1.png", 60, "w3000 n1", FoundX, FoundY, 380, 260, 1450, 850))
		Goto RecenterOnSystem_Escape
	
	if (NovaFindClick("pirates\center_system2.png", 60, "n1", FoundX, FoundY, 380, 260, 1450, 850))
		Goto RecenterOnSystem_Escape
		
	if (NovaFindClick("pirates\center_system3.png", 60, "n1", FoundX, FoundY, 380, 260, 1450, 850))
		Goto RecenterOnSystem_Escape

	if (NovaFindClick("pirates\center_system4.png", 60, "n1", FoundX, FoundY, 380, 260, 1450, 850))
		Goto RecenterOnSystem_Escape

	if (NovaFindClick("pirates\center_system5.png", 60, "n1", FoundX, FoundY, 380, 260, 1450, 850))
		Goto RecenterOnSystem_Escape
	
	return 0
	
RecenterOnSystem_Escape:	
	NovaFindClick("buttons\back_ships.png", 50, "w1000 n1", FoundX, FoundY, 0, 40, 210, 160)
	
	if (!NovaEscapeMenu())
		return 0
		
	return 1
}

;*******************************************************************************
; ZoomOut : Zoom out the map
;*******************************************************************************
ZoomOut()
{
	Send {Q Down}
	Sleep, 500
	Send {Q Up}
}

;*******************************************************************************
; ZoomIn : Zoom in the map
;*******************************************************************************
ZoomIn()
{
	Send {A Down}
	Sleep, 500
	Send {A Up}
}

