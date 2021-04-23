#include libs\JSON.ahk
#include utils.ahk


; scan area coordinates
global AreaX1 := 300
global AreaY1 := 170
global AreaX2 := 1600
global AreaY2 := 980

global ScanResult := []
global ScanType := ""

json_str = 
(
{
    "whales": 1,
    "voids": 1,
    "pirates": 0
}
)

options := JSON.Load(json_str)
Res := Scan("falom", options)
SaveObjectToJSON(Res, "out.json")

;*******************************************************************************
; Scan : Scans the given system name
; systemname : Name of the system to look in data\systems.json
; options : object containing the liste of items and wether if they should be
; looked for or not
;*******************************************************************************
; Scans the given system name
Scan(systemname, options)
{
    global AreaX1, AreaY1, AreaX2, AreaY2
    global ScanType
    
    systems := GetObjectFromJSON("data\systems.json")
    if (systems == "")
    {
        LOG("ERROR : (scan) Could Not load systems.json, cancelling", 2)
        return 0
    }
    
    SystemWidth  := systems[systemname].radius * 1000
    SystemHeight := SystemWidth
    
    MapStepX := 1000
    MapStepY := 600
    
    CurrentX := -(SystemWidth / 2)
    CurrentY :=  (SystemHeight / 2)
	LoopY := (SystemHeight / MapStepY) + 1 
    LoopX := (SystemWidth / MapStepX) + 1 
    
    
    ; setup the scan results
    ScanResult := []
    
    for key, val in options
        if (val)
            ScanResult[key] := []
    
    ; Scan the ressources on the map and fill the ressources array
	; Loop Y
	Loop, % LoopY
	{
		; Loop X
		Loop, % LoopX
		{
			MapMoveToXY(CurrentX, CurrentY)

            for key, val in options
            {
                if (val)
                {
                    ScanType := type
                    NovaFindClick(Format("target\{1}.png", ScanType), 80, "e n0 FuncHandleScan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)          
                }
            }
			
			CurrentX := CurrentX + MapStepX
	
		}
		
		CurrentX := CurrentX - MapStepX
		MapStepX := -MapStepX
		CurrentY := CurrentY - MapStepY
	}
	
    return ScanResult.Clone()
}

;*******************************************************************************
; HandleScan : Handle the collection of a single ressource
; ResX, ResY : Window coordinate of the location of the resource
;*******************************************************************************
HandleScan(ResX, ResY)
{
	global MainWinX, MainWinY
    global MainWinW, MainWinH
	global WinBorderX, WinBorderY
    global ScanResult, ScanType
    
	ResX := (ResX - MainWinX - WinBorderX - (MainWinW / 2)) + MapPosX 
	ResY := MapPosY - (ResY - MainWinY - WinBorderY - (MainWinH / 2))
	
	
    index:= ScanResult[ScanType].Length() + 1
    ScanResult[ScanType][index] :=[]
    ScanResult[ScanType][index].x := ResX
    ScanResult[ScanType][index].y := ResY
    
    Log(Format("Found a '{3}' at ({1:i},{2:i}), Total={4}", ResX, ResY, ScanType, ScanResult[ScanType].Length()))
}