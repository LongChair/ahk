#include globals.ahk
#include utils.ahk
#include pirates.ahk


;*******************************************************************************
; whale_assist : Will try to assis others on whales
;*******************************************************************************

Whale_Assist()
{
	global WhaleX, WhaleY
	global WinCenterX, WinCenterY
	global MapPosX, MapPosY
	global WhaleKillCount
	
	Command = ""
	
	
	; LOOK FOR AN INBOX MESSAGE
	; click the "mail" Menu
	Log("Clicking mail menu ...")
	if (!NovaFindClick("buttons\mail_menu.png", 50, "w2000 n1", FoundX, FoundY, 1270, 30, 1370, 120))
	{
		Log("ERROR : failed to find the mail menu button. exiting", 2)
		return 0
	}
	
	; click teh personnal messages
	Log("Clicking personnal tab ...")
	if (!NovaFindClick("buttons\personnal_message_off.png", 50, "w10000 n1", FoundX, FoundY, 550, 170, 780, 230))
	{
		Log("ERROR : failed to find the personnal message off button. exiting", 2)
		return 0
	}
	
	if (!NovaFindClick("buttons\personnal_message_on.png", 50, "w2000 n1", FoundX, FoundY, 550, 170, 780, 230))
	{
		Log("ERROR : failed to find the personnal message on button. exiting", 2)
		return 0
	}
	
	Log("Looking for message...")
	if (NovaFindClick("buttons\whale_message.png", 50, "w500 n1", FoundX, FoundY, 100, 300, 700, 430))
	{
	
		Log("Got WHALE message !")
		Command := "WHALE"
				
		Sleep, 1000
	}
	
	if (NovaFindClick("buttons\recall_message.png", 50, "w500 n1", FoundX, FoundY, 100, 300, 700, 430))
	{
		Log("Got RECALL message !")
		Command := "RECALL"
			
		Sleep, 1000
	}
	
	while (NovaFindClick("buttons\message_delete.png", 50, "w1000 n1", FoundX, FoundY, 1500, 930, 1780, 1040))
	{
		Log("Deleting message ...")
		Sleep, 1000
	}


	while NovaFindClick("buttons\back_message.png", 50, "w1000 n1", FoundX, FoundY, 0, 40, 210, 160)
	{
		Log("Going back from message screen...")
		Sleep, 1000
	}
	
	
	; LOCATE THE WHALE
	; Go to the proper system
	if (!GoToFavorite(1))
	{
		Log(Format("ERROR : failed to favorite {1}. exiting", 4), 2)
		return 0
	}
	
	MapPosX := 0
	MapPosY := 0

	; Check if whale is still there or search it
	if ((WhaleX <> 0) && (WhaleY <> 0))
	{
		Log(Format("Going to Whale at ({1},{2})", WhaleX, WhaleY))
		
		MapMoveToXY(WhaleX, WhaleY)
		
		if (!NovaFindClick("pirates\whale.png", 80, "w1000 n0", FoundX, FoundY, 860, 470, 1020, 630))
		{
			Log("Whale disapeared, resetting...")
			WhaleX := 0
			WhaleY := 0
		}
		Else
		{
			Log(Format("Whale still at ({1},{2})", WhaleX, WhaleY))
		}
	}
	Else
	{
		; Scan the whale system
	
		WhaleX := 0
		WhaleY := 0
		
		Log("Scanning map for whale ...")
		ScanMap("WhaleSystem")
		
		if ((WhaleX <> 0) && (WhaleY <> 0))
			Log(Format("We got a whale at {1},{2}}", WhaleX, WhaleY))
		
	}
	
	
	
	if (Command == "WHALE")
	{
		Log("Processing WHALE command !")
		
		
		if ((WhaleX <> 0) && (WhaleY <> 0))
		{
			Log(Format("Going to whale at {1},{2}}", WhaleX, WhaleY))
			MapMoveToXY(WhaleX, WhaleY)
				
			if (!NovaFindClick("pirates\whale.png", 80, "w1000 n1", FoundX, FoundY, 860, 470, 1020, 630))
			{
				LOG("ERROR : Could Not find the whale", 2)
				return 0
			}
			
			; Validate it's a pirate
			if (!ValidateWhale(WinCenterX, WinCenterY, Valid))
			{
				NovaEscapeClick()
				LOG("ERROR : whale Validation failed, exiting", 2)
				
				return 0
			}

			NovaEscapeClick()
			Sleep, 1000

			Log("Sending fleets to whale ...")
			; now we have the whale at center screen, click right next
			NovaLeftMouseClick(WinCenterX + 35, WinCenterY + 35)
			
			if (!NovaFindClick("buttons\group_move.png", 50, "w2000 n1", FoundX, FoundY, 1230,380, 1400, 480))
			{
				LOG("ERROR : Could Not find the menu image for groupmove, different menu popped up ?", 2)
				return 0
			}
			
			Sleep, 2000
			
			Log("Selecting all fleets ...")
			; click on select All
			NovaLeftMouseClick(1436,182)
			Sleep, 1000
			
			; click on OK
			NovaLeftMouseClick(1600,800)
			Sleep, 1000
			
			Log("Waiting for fleets to be idle...")
			if (!WaitForFleetsIdle(180))
			{
				LOG("ERROR : while waiting for fleets to be idle", 2)
				return 0
			}
			
			Log("Waiting for whale to go away...")
			; wait for whale to be killed.
			while (NovaFindClick("pirates\whale.png", 80, "w1000 n0", FoundX, FoundY, 860, 470, 1020, 630))
			{
				Sleep, 1000 
			}
			
			Log("Waiting for fleets to be idle...")
			if (!WaitForFleetsIdle(120))
			{
				LOG("ERROR : while waiting for fleets to be idle", 2)
				return 0
			}
			
			Log("Recalling fleets...")
			; recall the fleets
			RecallAllFleets()
			
		}
		Else
		{
			Log("We had a WHALE command, but no whale found.")
		}
		
	}
	
	if (Command == "RECALL")
	{
		Log("Recalling fleets...")
		; recall the fleets
		RecallAllFleets()
	}
	
	return 1

}

;*******************************************************************************
; Whale_Farm : Will try to farm whales
;*******************************************************************************
Whale_Farming()
{
	global MapPosX, MapPosY
	global WinCenterX, WinCenterY
	global WhaleX, WhaleY
	global FarmingWhales
	global Voids
	global LastWhalekillTime
	global VoidCollected
	global PlayerConfig
	
	if (PlayerConfig.WHALES.currentkillpower >= PlayerConfig.WHALES.maxkillpower)
	{
		Log("we have killed enough whales, waiting ...")
		Sleep, 10000
		return 1
	}
	
	; LOCATE THE WHALE
	; Go to the proper system
	if (!GoToFavorite(4))
	{
		Log(Format("ERROR : failed to favorite {1}. exiting", 4), 2)
		return 0
	}
	
	
	; Scan the whale system
	FarmingWhales := 1
	Farming := 0
	FarmingMulti :=0
	MapPosX := 0
	MapPosY := 0
	WhaleX := 0
	WhaleY := 0
	WhaleSize := 0
	Voids := []
	VoidCount := 0
	
	Log("Scanning map for whale ...")
	ScanMap("WhaleSystem")
	SortResList(Voids)
	
	if ((WhaleX <> 0) && (WhaleY <> 0))
	{
		
		Log(Format("Going to whale at {1},{2}}", WhaleX, WhaleY))
		MapMoveToXY(WhaleX, WhaleY)
			
		if (!NovaFindClick("pirates\whale.png", 80, "w1000 n1", FoundX, FoundY, 860, 470, 1020, 630))
		{
			LOG("ERROR : Could Not find the whale", 2)
			goto Whale_Farming_End
		}
			
		; Validate it's a whale
		if (!ValidateWhale(WinCenterX, WinCenterY, Valid))
		{
			NovaEscapeClick()
			LOG("ERROR : whale Validation failed, exiting", 2)
			goto Whale_Farming_End
		}
		
		if (!Valid)
		{
			NovaEscapeMenu()
			LOG("Whale is not valid, exiting")
			goto Whale_Farming_End
		}
		
		; we check whale size
		if NovaFindClick("pirates\valid\20M.png", 50, "w1000 n0", FoundX, FoundY, 450, 550, 820, 640)
			WhaleSize := 20
		if NovaFindClick("pirates\valid\10M.png", 50, "w1000 n0", FoundX, FoundY, 450, 550, 820, 640)
			WhaleSize := 10
		if NovaFindClick("pirates\valid\6M.png", 50, "w1000 n0", FoundX, FoundY, 450, 550, 820, 640)
			WhaleSize := 6
		
		msg := Format("We seem to have a {1}M Whale, Count {2}M / {3}M", WhaleSize, PlayerConfig.WHALES.currentkillpower, PlayerConfig.WHALES.maxkillpower)
		Log(msg)
		SendDiscord(Format(":whale: {1}", msg))
		
		; Monitor the whale for some time and leave others a chance to kill it
		NovaEscapeMenu()
		
		Loop, 100
		{
			if (!NovaFindClick("pirates\whale.png", 80, "w1000 n0", FoundX, FoundY, 860, 470, 1020, 630))
			{
				LOG("whale is gone or was killed", 1)
				SendDiscord(":thumbsdown: whale is gone or was killed")
				goto Whale_Farming_End
			}
			Else
				Sleep, 1000
		}

		; now kill it.
		if (!NovaFindClick("pirates\whale.png", 80, "w1000 n1", FoundX, FoundY, 860, 470, 1020, 630))
		{
			LOG("ERROR : Could Not find the whale to kill", 2)
			goto Whale_Farming_End
		}
			
		; check if we don't have any yellow fleet in the area
		if (NovaFindClick("targets\yellow.png", 50, "w100 n1", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2))
		{
			LOG("ERROR : (attack) Will not attack, yellow fleet detected, cancelling", 2)
			return 1
		}


		; attack the whale
		if (!NovaFindClick("buttons\group_attack.png", 50, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
		{
			LOG("ERROR : Could Not find the menu image for attack, different menu popped up ?", 2)
			return 0
		}


		if (NovaFindClick("buttons\red_continue.png", 50, "w1000 n1"))
		{
			Log("Avengers trigger validation")
			Sleep, 2000
		}
				
		Sleep, 1000
		
		Log("Selecting all fleets ...")
		; click on select All
		NovaLeftMouseClick(1436,182)
		Sleep, 1000
		
		; click on OK
		NovaLeftMouseClick(1600,800)
		Sleep, 1000
		
		Log("Waiting for fleets to be idle...")
		if (!WaitForFleetsIdle(240))
		{
			LOG("ERROR : while waiting for fleets to be idle", 2)
			return 0
		}
		
		Log("Recalling fleets...")
		; recall the fleets
		RecallAllFleets()
		
		PlayerConfig.WHALES.lastkilltime := A_TickCount
		PlayerConfig.WHALES.currentkillpower := PlayerConfig.WHALES.currentkillpower + WhaleSize
		
		SendDiscord(Format(":thumbsup: Whale Killed. (Total power = {1}M / {2}M)", PlayerConfig.WHALES.currentkillpower, PlayerConfig.WHALES.maxkillpower))
		
		WriteConfig()
	}
	Else
	{
		Delay := (A_TickCount - PlayerConfig.WHALES.lastkilltime) / 1000
		Log(Format("it's been {1} secs since last whale kill", Delay))
		
		if (Delay < (30 * 60) )
		;if (1)
		{
			; no whales, do we have voids
			while (Voids.Length() > 0)
			{
				VoidCoords := StrSplit(PeekClosestRes(Voids, 0, 0) , ",")
				VoidX := VoidCoords[2]
				VoidY := VoidCoords[3]
				
				Log(Format("Going to pick void at ({1}, {2}... {3} left})", VoidX, VoidY, Voids.Length()))
				MapMoveToXY(VoidX, VoidY)
				
				if (!NovaFindClick("pirates\void.png", 80, "w1000 n1", FoundX, FoundY, 830, 430, 1100, 700))
				{
					LOG("ERROR : Could Not find the void to collect, trying to find another one", 2)
					Goto Whale_Farming_NextVoid
				}
				
				; Validate it's a pirate
				if (!ValidateVoid(FoundX, FoundY, Valid))
				{
					NovaEscapeClick()
					LOG("ERROR : Void Validation failed, exiting", 2)
					
					Goto Whale_Farming_NextVoid
				}
		
							
				; collect the void
				if (!NovaFindClick("buttons\collect.png", 80, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
				{
					NovaEscapeMenu()
					LOG("ERROR : Could Not find the menu image for collect, different menu popped up ?", 2)
					goto Whale_Farming_NextVoid
				}
				

				if (Valid)
				{
					VoidCollected := VoidCollected + 1
					VoidCount := VoidCount +1
					LOG(format("Void collected +{1}, ({2} Total)",VoidCount, VoidCollected))
				}
				Else
				{
					LOG(format("RSS collected ({1} Total)",VoidCollected))
				}
	
				
				Sleep, 1000
				
				Whale_Farming_NextVoid:
			}
			
			if (VoidCount > 0)
				SendDiscord(Format("Void collected +{1}, ({2} Total)", VoidCount, VoidCollected))
		}
		Else
			Log("It's been too long since last whale kill, not collecting.")
	}

	Whale_Farming_End:
	return 1
}