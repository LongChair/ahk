
#include libs\JSON.ahk
#include utils.ahk

; Attacks a target with validation, the params array is a json structure
;{
;	"pirates" :
;	{
;		"approach": false,
;		"fleets": [],
;		"location": {
;			"x": 0,
;			"y": 0
;		},
;		"target" : "pirate",
;		"validation": "pirate"
;	}
;}



Attack(params, x, y)
{
    global WinCenterX, WinCenterY
	global AreaX1, AreaY1, AreaX2, AreaY2
	global Context

	OnStartAttack(params)
	
    ; move to the pirate location
    MapMoveToXY(x, y)

	; Wait before attacking eventually
	WaitSec := GetObjectProperty(params, "wait", 0)
	if (WaitSec)
	{
		LOG(Format("Waiting {1} seconds before attacking....", WaitSec))
		Sleep, WaitSec*1000
	}
	
	; check if we don't have any yellow fleet in the area
	if (NovaFindClick("targets\yellow.png", 50, "w100 n0", FoundX, FoundY, 750, 400, 1150, 720))
    {
        LOG("ERROR : (attack) Will not attack, yellow fleet detected, cancelling", 2)
		OnCancelAttack(params, "Yellow Fleet Detected !")
        return 1
    }
	
	if (NovaFindClick("targets\blue.png", 50, "w100 n0", FoundX, FoundY, 750, 400, 1150, 720))
    {
        LOG("Other friendly ships are around", 1)
		params.alone := false
    }
	Else
		params.alone := true

    ; we look for the target and click it
    if (!NovaFindClick(Format("targets\{1}.png", params.target), 90, "w1000 n1", FoundX, FoundY, 800, 450, 1120, 650))
    {
        LOG(Format("ERROR : (attack) Could Not find the target for '{1}', cancelling", params.target), 2)
		OnCancelAttack(params, "Target not visible anymore !")
		NovaleftMouseClick(WinCenterX/2, WinCenterY/2)
    }

    ; we validate the target
    if (!NovaFindClick(Format("targets\validation\{1}.png", params.target), 80, "w2000 n0", FoundX, FoundY, 600, 470, 790, 540))
    {
		LOG(Format("ERROR : (attack) Could Not validate the target for '{1}', cancelling", params.target), 2)
		OnCancelAttack(params, "Could Not validate target!")
        NovaEscapeMenu()
        return 1
    }
    
	OnTargetValidated(params)
	
	approach := GetObjectProperty(params, "approach", false)
    if (approach)
    {
		Sleep, 500
        NovaEscapeMenu()
           
        ;click aside the target
        NovaLeftMouseClick(WinCenterX + 35, WinCenterY + 35)

        ; Click the group move button
		LOG(Format("Approaching '{1}'...", params.target), 1)
        if (!NovaFindClick("buttons\group_move.png", 80, "w2000 n1", FoundX, FoundY, 1230,380, 1400, 480))
        {
            LOG("ERROR : (attack) Could Not find the group move menu, cancelling", 2)
            NovaEscapeMenu()
            return 1
        }
		
		Sleep, 1000
    }
    else
    {
        ; attack the target
        if (!NovaFindClick("buttons\group_attack.png", 50, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
        {
            LOG("ERROR : (attack) Could Not find the group attack menu, different menu popped up ?", 2)
            return 1
        }

        ; in case we have avengers popup
        if (NovaFindClick("buttons\red_continue.png", 50, "w1000 n1"))
        {
            Log("Avengers trigger validation")
            Sleep, 2000
        }
    }
    
    ; now select fleets
	ret := SelectFleets(params.fleets)
    if ( ret != 1)
        return ret
    
	
	; save the fleet position
	for i, fleet in params.fleets
    {
        switch fleet
        {
            case "all":
				Loop, 6 
				{
					Context.FleetPositions[i].x := x
					Context.FleetPositions[i].y := y
				}
                
            default :
				Context.FleetPositions[fleet].x := x
				Context.FleetPositions[fleet].y := y
		}
	}
	
    ; saves the last attack time for that type
    Context.killtimes[params.target] := A_Now

	OnSendingFleet(params)
	
    ; Increments the target counter and saves the stats file
	if (!approach)
	{
		key := Format("kill.{1}", params.target)
		AddStats(key, 1)    	
	}
	
	recall := GetObjectProperty(params, "recall", false)
	if (recall OR approach)
	{
		Log("Waiting for fleets to be idle...")
		if (!WaitForFleetsIdle(300))
		{
			LOG("ERROR : while waiting for fleets to be idle", 2)
			return 0
		}
		
	}
	
	if (recall)
	{	
		Log("Recalling fleets...")
		; recall the fleets
		RecallAllFleets()
	}
		
	if (approach)
		return 2
	else
	{
		OnTargetKilled(params)
		return 1
	}
}


; Select the fleets 
; returns : 1 if success, 0 if failed, 2 if fleets was busy
SelectFleets(Fleets)
{
    for i, fleet in Fleets
    {
        switch fleet
        {
            case "all":
                Log("Selecting all fleets ...")
                ; click on select All
                NovaLeftMouseClick(1436,182)
                Sleep, 1000
                
                
            default :
                GetAttackFleetArea(fleet, X1, Y1, X2, Y2)
				
				; check fleet status
				if (!NovaFindClick("buttons\fleetstatus_idle.png", 80, "w1000 n0", FoundX, FoundY, X1, Y1, X2, Y1 + 50))
				{
					if (!NovaFindClick("buttons\fleetstatus_docked.png", 80, "w1000 n0", FoundX, FoundY, X1, Y1, X2, Y1 + 50))
					{

						LOG(Format("INFO : (select) Fleet {1} is not idle, skipping ...", fleet))
						NovaEscapeClick()
                        return 2
					}
				}

				NovaLeftMouseClick(X1+100, (Y1+Y2)/2)
        }
    }
    
    ; click Ok button
    if (!NovaFindClick("buttons\OKFleets.png", 50, "w1000 n1", FoundX, FoundY, 1390, 760, 1633, 850))
    {
        LOG("ERROR : (select) Failed to find the OK button for fleets, exiting.")
        return 0
    }

    return 1
}

; OnStartAttack : called when entering the attack
OnStartAttack(params)
{
	switch params.target
	{
		case "whale":
			NextTime := A_Now
			NextTime += 45, Minutes
			FormatTime, TimeString, %NextTime%, HH:mm
			SendDiscord(Format(":whale: We found a whale! (Next one at ~{1})", TimeString))
	}
}

; OnCancelAttack : called when entering the cancelled
OnCancelAttack(params, Reason)
{
	switch params.target
	{
		case "whale":
			SendDiscord(Format(":warning: Attack cancelled : {1}", Reason))
	}
}

; OnTargetValidated : called when the target was validated
OnTargetValidated(params)
{
	switch params.target
	{
		case "whale":
		
			; we check whale size
			if NovaFindClick("pirates\valid\20M.png", 50, "w100 n0", FoundX, FoundY, 450, 550, 820, 640)
				WhaleSize := 20
			if NovaFindClick("pirates\valid\10M.png", 50, "w100 n0", FoundX, FoundY, 450, 550, 820, 640)
				WhaleSize := 10
			if NovaFindClick("pirates\valid\6M.png", 50, "w100 n0", FoundX, FoundY, 450, 550, 820, 640)
				WhaleSize := 6
				
			if (params.alone)
				AloneString := "We are alone"
			Else
				AloneString := "We are NOT alone"
				
			SendDiscord(Format(":whale: We have validated a **{1}M** whale, ({2})", WhaleSize, AloneString))
			
	}
}

; OnSendingFleet : called when sending fleets in attack
OnSendingFleet(params)
{
	switch params.target
	{
		case "whale":
			if (params.approach)
				SendDiscord(":rocket: sending fleets (approach)...")
			Else
				SendDiscord(":rocket: sending fleets (attack)...")
	}
}


; OnTargetKilled : called when target was killed
OnTargetKilled(params)
{
	switch params.target
	{
		case "whale":
			SendDiscord(":thumbsup: Whale killed.")
	}
}


