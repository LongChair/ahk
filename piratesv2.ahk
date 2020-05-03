#include globals.ahk
#include utils.ahk
#include pirates.ahk
#include resources.ahk


;*******************************************************************************
; FarmPirates_v2 : Will try to find a pirate, kill it and collect resource
;*******************************************************************************
FarmPirates_v2()
{
    global FleetPosX, FleetPosY
    global MaxPlayerFleets, Window_ID
	global WinCenterX, WinCenterY
    global KilledCount
	Global Pirates, CurrentResType
	
    FleetsSpan := Object( 1, 3, 4, 6)
    FleetAvailable := []
    KilledList := []
	
	
	Loop 500
	{
		for StartFleet, EndFleet in FleetsSpan
		{
		   
			; Open the fleets tab
			if !PopRightMenu(1, "FLEETS")
			{
				Log("ERROR : failed to popup main menu for fleets. exiting", 2)
				return 0
			}
			
			
			; click the startfleet
			LOG(Format("Switching to Fleet {1} system ...",StartFleet))
			GetFleetArea(StartFleet, X1, Y1, X2, Y2)
			NovaLeftMouseClick((X1+X2)/2, (Y1+Y2)/2)
			
							
			; click the "Voir" Menu
			if (!NovaFindClick("buttons\voir.png", 40, "w5000 n1", FoundX, FoundY, 1050, 880, 1250, 950))
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
			

			Sleep, 1000	
				
			; Center on system
			if (!RecenterOnSystem())
			{
				Log("ERROR : failed to recenter on system. exiting", 2)
				return 0
			}
			
			; scan system 
			CurrentResType := "PIRATE"
			Pirates := []
			ScanMap("", 0)
			SortResList(Pirates)
			Log(Format("We found {1} Pirates", Pirates.Length()))
			

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
			   
			   if NovaFindClick("buttons\manage_button.png", 70, "n0", FoundX, FoundY, X1, Y1, X2, Y2)
			   {
					FleetAvailable[iFleet] := 1
					StrStatus := Format("{1} {2}", strStatus, iFleet)
			   }
			   Else
			   {
					if NovaFindClick("buttons\recall_button.png", 70, "n0", FoundX, FoundY, X1, Y1, X2, Y2)
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
			Log(StrStatus)
			PopRightMenu(0)
			
			
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
					
					; Click Pirate
					MapMoveToXY(PirateX, PirateY)
					NovaLeftMouseClick(WinCenterX, WinCenterY)

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
						NovaEscapeMenu()
						
						;; Center on system
						if (!RecenterOnSystem())
						{
							Log("ERROR : failed to recenter on system. exiting", 2)
							return 0
						}
						
						Goto FarmPirates_v2_New_Pirate
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
					
					
	FarmPirates_v2_NextPirate:
					
				
					if (!WaitNovaScreen("SYSTEME", 30))
					{
						Log("ERROR : failed wait for system screen. exiting", 2)
						return 0
					}
					
				}
			
				FarmPirates_v2_Next_group:
			}
			
			FarmPirates_v2_Killing_Done:
			
		}
	}
		
    return 1
}



;*******************************************************************************
; RecenterOnSystem : Recenter by clicling on system center
;*******************************************************************************
RecenterOnSystem()
{
	global MapPosX, MapPosY
	
	ZoomOut()
			
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
	if (!NovaEscapeMenu())
		return 0
		
	ZoomIn()
	
	MapPosX := 0
	MapPosY := 0
		
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
