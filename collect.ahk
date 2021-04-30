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
    
    ; we look for the target and click it
    if (!NovaFindClick(Format("targets\{1}.png", params.target), 30, "w1000 n1", FoundX, FoundY, 860, 470, 1020, 630))
    {
        LOG(Format("ERROR : (collect) Could Not find the target for '{1}', cancelling", params.target), 2)
        return 1
    }

    ; we validate the target
    if (!NovaFindClick(Format("targets\validation\{1}.png", params.target), 80, "w1000 n0", FoundX, FoundY, 600, 470, 790, 580))
    {
        LOG(Format("ERROR : (collect) Could Not validate the target for '{1}', cancelling",params.validation), 2)
        NovaEscapeMenu()
        return 1
    }
    
    ; Collect
	if (!NovaFindClick("buttons\collect.png", 50, "w2000 n1", FoundX, FoundY, 500,175, 1600, 875))
	{
		LOG("ERROR : (collect) Could Not find the group attack menu, different menu popped up ?", 2)
		return 1
	}
	
	while (!NovaFindClick("buttons\ceg.png", 60, "w2000 n0", FoundX, FoundY, 1700, 40, 1960, 150))
	{
		NovaEscapeClick()
		Sleep, 500
	}
		
    return 1
}
