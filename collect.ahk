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
    
    ; move to the pirate location
    MapMoveToXY(x, y)
	
	scan := GetObjectFromJSON("data\scan.json")
    
    ; we look for the target and click it
    if (!NovaFindClick(Format("targets\{1}.png", params.target), scan.levels[params.target], "w1000 n1", FoundX, FoundY, 830, 440, 1020, 630))
    {
        LOG(Format("ERROR : (collect) Could Not find the target for '{1}', cancelling", params.target), 2)
        return 1
    }

    ; we validate the target
    if (!NovaFindClick(Format("targets\validation\{1}.png", params.target), 80, "w1000 n0", FoundX, FoundY, 600, 470, 790, 580))
    {
        LOG(Format("ERROR : (collect) Could Not validate the target for '{1}', cancelling",params.target), 2)
        NovaEscapeMenu()
        return 1
    }
    
    ; Collect
	if (!NovaFindClick("buttons\collect.png", 50, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
	{
		LOG("ERROR : (collect) Could Not find the collect buttons in menu, different menu popped up ?", 2)
		return 1
	}
	
	key := Format("collect.{1}", params.target)
	AddStats(key, 1)    
	OnCollect(params)
	
	while (!NovaFindClick("buttons\ceg.png", 60, "w2000 n0", FoundX, FoundY, 1700, 40, 1960, 150))
	{
		NovaEscapeClick()
		Sleep, 500
	}
		
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
	}
}

