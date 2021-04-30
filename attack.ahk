
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
	global FleetPositions
	global AreaX1, AreaY1, AreaX2, AreaY2
	global Context
    	
    ; move to the pirate location
    MapMoveToXY(x, y)

	; check if we don't have any yellow fleet in the area
	if (NovaFindClick("targets\yellow.png", 50, "w100 n1", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2))
    {
        LOG("ERROR : (attack) Will not attack, yellow fleet detected, cancelling", 2)
        return 1
    }


    ; we look for the target and click it
    if (!NovaFindClick(Format("targets\{1}.png", params.target), 80, "w1000 n1", FoundX, FoundY, 800, 450, 1120, 650))
    {
        LOG(Format("ERROR : (attack) Could Not find the target for '{1}', cancelling", params.target), 2)
        return 1
    }

    ; we validate the target
    if (!NovaFindClick(Format("targets\validation\{1}.png", params.target), 80, "w1000 n0", FoundX, FoundY, 600, 470, 790, 540))
    {
       LOG(Format("ERROR : (attack) Could Not validate the target for '{1}', cancelling",params.validation), 2)
        NovaEscapeMenu()
        return 1
    }
    
    if (GetObjectProperty(params, "approach", false))
    {
        NovaEscapeMenu()
           
        ;click aside the target
        NovaLeftMouseClick(WinCenterX + 35, WinCenterY + 35)

        ; Click the group move button
        if (!NovaFindClick("buttons\group_move.png", 80, "w2000 n1", FoundX, FoundY, 1230,380, 1400, 480))
        {
            LOG("ERROR : (attack) Could Not find the group move menu, cancelling", 2)
            NovaEscapeMenu()
            return 1
        }             
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
    
	; check if we have to wait for idel fleets
	if (GetObjectProperty(params, "wait", false))
	{
		
			
	}
	
	; save the fleet position
	for i, fleet in params.fleets
    {
        switch fleet
        {
            case "all":
				Loop, 6 
				{
					FleetPositions.fleet[i].x := x
					FleetPositions.fleet[i].y := y
				}
                
            default :
				FleetPositions.fleet[fleet].x := x
				FleetPositions.fleet[fleet].y := y
		}
	}
	SaveFleetPositions()

    ; saves the last attack time for that type
    Context.killtimes[params.target] := A_Now


    ; Increments the target counter and saves the stats file
	key := Format("kill.{1}", params.target)
	AddStats(key, 1)    
    SaveContext()
    
    return 1
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

; get fleet position
GetFleetPosition(index)
{
	global FleetPositions
	
			; load from File
	if (FleetPositions == "")
		FleetPositions := GetObjectFromJSON("data\fleets.json")
	
	if index is integer
		return FleetPositions.fleet[index]
	Else
		return FleetPositions.fleet[1]
}

SaveFleetPositions()
{
	global FleetPositions
	SaveObjectToJSON(FleetPositions, "data\fleets.json")
}