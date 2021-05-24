#include libs\JSON.ahk
#include utils.ahk

; Attacks a target with validation, the params array is a json structure
;{
;	"debris" :
;	{
;		"location": {
;			"x": 0,
;			"y": 0
;		},
;		"target" : "debris",
;		"validation": "debris"
;	}
;}

collect(params, x, y)
{
    global WinCenterX, WinCenterY
	global ScanInfo
    
    ; move to the pirate location
    MapMoveToXY(x, y)
	
    
	if (!NovaFindClick("targets\door.png", 30, "w100 n0", FoundX, FoundY, 600, 300, 1200, 800))
    {
        LOG(Format("(collect) Found a door in the area, cancelling"), 1)
        return 1
    }


    ; we look for the target and click it
    if (!NovaFindClick(Format("targets\{1}.png", params.target), ScanInfo.levels[params.target], "w1000 n1", FoundX, FoundY, 830, 440, 1020, 630))
    {
        ;LOG(Format("ERROR : (collect) Could Not find the target for '{1}', cancelling", params.target), 2)
        ;return 3
		NovaleftMouseClick(WinCenterX , WinCenterY)
    }

    ; we validate the target
	if (params.validation != "")
		Validation := params.validation 
	Else
		Validation := params.target
		
    if (!NovaFindClick(Format("targets\validation\{1}.png", Validation), 80, "w1000 n0", FoundX, FoundY, 600, 470, 790, 580))
    {
        LOG(Format("ERROR : (collect) Could Not validate the target for '{1}', cancelling",params.target), 2)
        NovaEscapeMenu()
        return 3
    }
    
    ; Collect
	if (!NovaFindClick("buttons\collect.png", 50, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
	{
		LOG("ERROR : (collect) Could Not find the collect buttons in menu, different menu popped up ?", 2)
		
		if (NovaFindClick("buttons\favori.png", 50, "w2000 n1", FoundX, FoundY, 1200,300, 1600, 700))
		{
			; if we have the menu, discard it
			NovaEscapeMenu()
		}
		
		return 1
	}
	
	NoWorkships :=0
	while (!NovaFindClick("buttons\ceg.png", 60, "w2000 n0", FoundX, FoundY, 1700, 40, 1960, 150))
	{
		NoWorkships := 1
		NovaEscapeClick()
		Sleep, 500
	}
	
	if (NoWorkships)
	{
		LOG("We seem to have no more workships", 1)
		return 2
	}
	
	key := Format("collect.{1}", params.target)
	AddStats(key, 1)    
	OnCollect(params)		
		
    return 1
}


; OnTargetKilled : called when target was killed
OnCollect(params)
{
	global Context
	
	switch params.target
	{
		case "void":
			SendDiscord(Format(":gem: +1 void collected, ({1} Total).", Context.Stats["collect.void"]))
			
		case "debris":
			SendDiscord(Format(":coin: +1 rss collected, ({1} Total).", Context.Stats["collect.debris"]))
	}
}

