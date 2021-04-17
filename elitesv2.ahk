#include globals.ahk
#include utils.ahk


;*******************************************************************************
; FarmElites_v2 : Will try to find elites, kill it and collect resource
;*******************************************************************************
FarmElites_v2(FavoriteID, Type)
{
	global MapPosX, MapPosY
	global EliteKill
	
	IniPath = %A_ScriptDir%\images\systems\FarmElite\system.ini
	SpotID := 1

	If (Type = 1)
		ValidationImage := "pirates\valid\Elite.png"
	else
		ValidationImage := "pirates\valid\kraken.png"
	
	Loop 
	{
		Section := Format("SPOT{1}", SpotID)
		IniRead, SpotX, %IniPath%, %Section%, X, 0
		IniRead, SpotY, %IniPath%, %Section%, Y, 0
		
		if ((SpotX=0) And (SpotY=0))
		{
			Log("No more spots to process", 1)
			return 1
		}
			
	
		; Go to the proper system
		if (!GoToFavorite(FavoriteID))
		{
			Log(Format("ERROR : failed to favorite {1}. exiting", FavoriteID), 2)
			return 0
		}
		MapPosX := 0
		MapPosY := 0

		; Move to spot coordinates
		Log(Format("Processing Spot {1} at ({2}, {3})", SpotID, SpotX, SpotY))
		MapMoveToXY(SpotX, SpotY)
	
	
		 ; try to find elite
		if (NovaFindClick("pirates\Elite.png", 50, "w1000 n0", FoundX, FoundY))
        {
        
			Log("Found An elite, attacking ...")
			
			;click on the pirate
			NovaLeftMouseClick(FoundX, FoundY)
			
			; validate if pirate is to be killed
			if (!ValidateTarget(ValidationImage, WinCenterX, WinCenterY, Valid))
			{
				NovaEscapeClick()
				LOG("ERROR : Target Validation failed, exiting", 2)
				return 0			
			}
					
			
			if (!Valid)
			{
				
				NovaEscapeClick()
				
				; we need to reclaibrate position
				Goto FarmElites_v2_NextSpot
			}
		   
			; attack the pirate
			if (!NovaFindClick("buttons\group_attack.png", 50, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
			{
				LOG("ERROR : Could Not find the menu image for group attack, different menu popped up ?", 2)
				return 0
			}
			
			
			if (NovaFindClick("buttons\red_continue.png", 50, "w1000 n1"))
			{
				Log("Avengers trigger validation")
				Sleep, 2000
			}
	

			Log("Selecting all fleets ...")
			; click the select all 
			if (NovaFindClick("buttons\selectall.png", 50, "w1000 n1", FoundX, FoundY, 1300, 140, 1400, 220))
			{
				Log("Avengers trigger validation")
				Sleep, 2000
			}

			

			Log("Selecting Ok button ...")
			  ; try to find elite
			if (!NovaFindClick("buttons\OKFleets.png", 50, "w1000 n1", FoundX, FoundY, 1390, 760, 1633, 850))
			{
			    LOG("ERROR : Failed to find the OK button for fleets, exiting ...")
				return 0
			}
        
            ; make sure we start the move
            Sleep 1000
				
			FormatTime DayDate,, dd_MM_yyyy
            FileLog(Format("Killed Elite #{1}", EliteKill), Format("Elites_{1}.txt",DayDate))
			Log(Format("Killed Elite Count is {1}", EliteKill))
			EliteKill := EliteKill + 1

            ; now Wait for all fleets to be there
            Log("Waiting for fleets to be idle...")
            if (!WaitForFleetsIdle(60))
            {
                Log("ERROR : failed to wait for fleets to be idle after attack, exiting.", 2)
				return 0
            }            
            
			Log("recalling all fleets...")
            ; recall all the fleets
            if (!RecallAllFleets())
            {
                Log("ERROR : failed to recall fleets to station", 2)
                return 0
                
            }
			
        }
		
		
		CollectDebris := 1
		if (CollectDebris)
		{
			if (NovaFindClick("pirates\debris.png", 30, "w100 n0", FoundX, FoundY, 250, 220, 1560, 1050))
			{
				LOG("We have a debris, trying to collect...")
				; Click on the pirate
				if (!ClickMenuImage(FoundX, FoundY, "buttons\collect.png"))
				{
					Log("ERROR : failed to find click collect, exiting.", 2)
				}
				
				Count := 0
				
				; in case we have the no more meca popup
				while (!NovafindClick("Buttons\player.png", 50, "w2000 n0"))
				{
					NovaEscapeClick()										
					Count := Count + 1
					
					if (Count > 10)
					{
						Log("ERROR : failed to escape, exiing", 2)
						return 0
					}
				}
		
			}
		}


	FarmElites_v2_NextSpot:
		SpotID := SpotID + 1
	}
}