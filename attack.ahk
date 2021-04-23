
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


Attack(params)
{
    global WinCenterX, WinCenterY
    
    ; move to the pirate location
    MapMoveToXY(params.location.x, params.location.y)
    
    ; we look for the target and click it
    if (!NovaFindClick(Format("targets\{1}.png", params.target), 80, "w1000 n1", FoundX, FoundY, 860, 470, 1020, 630))
    {
        LOG("ERROR : (attack) Could Not find the target, cancelling", 2)
        return 1
    }

    ; we validate the target
    if (!NovaFindClick(Format("targets\validation\{1}.png", params.validation), 80, "w1000 n0", FoundX, FoundY, 600, 470, 790, 540))
    {
        LOG("ERROR : (attack) Could Not validate the target, cancelling", 2)
        NovaEscapeMenu()
        return 1
    }
    
    if (params.approach)
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
    if (!SelectFleets(params.fleets))
    {
        return 0
    }

    return 1
}


; Select the fleets 
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
                        return 1
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