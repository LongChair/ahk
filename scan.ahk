#include libs\JSON.ahk
#include utils.ahk


; scan area coordinates
global AreaX1 := 300
global AreaY1 := 170
global AreaX2 := 1600
global AreaY2 := 980

global ScanResult := []
global ScanType := ""


scan_trial()
{
	global Window_ID
	Window_ID := 0x135515f8
	
	key := "void"
	tolerance := 80
	ScanResult := []
	ScanResult[key] := []
	NovaFindClick(Format("targets\{1}.png", key), tolerance, "dx e n0 FuncHandle_Scan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)          
}

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
	global MapPosX, MapPosY
	global WinCenterX, WinCenterY
	
    
    scan := GetObjectFromJSON("data\scan.json")
    if (scan == "")
    {
        LOG("ERROR : (scan) Could Not load scan.json, cancelling", 2)
        return 0
    }
    
    MapStepX := 1000
    MapStepY := 600    
        
    if (0)
    {
        SystemWidth  := 2*(590 + (scan.systems[systemname].radius-1) * 260)
        SystemHeight := SystemWidth
        
        CurrentX := -(SystemWidth / 2)
        CurrentY :=  (SystemHeight / 2)
        LoopY := (SystemHeight / MapStepY) + 1 
        LoopX := (SystemWidth / MapStepX) + 1 
    }
    else
    {
        SystemWidth := scan.systems[systemname].width
        Systemheight := scan.systems[systemname].height
        
        LoopX := Ceil(SystemWidth / MapStepX) 
        LoopY := Ceil(SystemHeight / MapStepY)
        
        CurrentX := -(LoopX * MapStepX) / 2
        CurrentY :=  (LoopY * MapStepY) / 2
    }
    
    MapPosX := 0
	MapPosY := 0
		
    ; setup the scan results
	reuse := GetObjectProperty(options, "reuse", true)
	
	if (reuse)
	{
		ScanResult := LoadScan(systemname)
		
		if ((ScanResult["timestamp"] is time) AND (A_Now - ScanResult["timestamp"] < (10 * 60)))
		{
			for i, key in options.targets
				if (ScanResult[key].Length() == 0)
				{
					LOG("Can't reuse last scan, it's empty.")
					Goto Scan_DoScan
				}
					
			LOG("Reusing last scan.")
			return ScanResult
		}
	}
	
	Scan_DoScan:
    ScanResult := []
    
    for i, key in options.targets
		ScanResult[key] := []
   	
    ; Scan the ressources on the map and fill the ressources array
	; Loop Y
	Loop, % (LoopY +1)
	{
		; Loop X
		Loop, % (LoopX +1)
		{
			MapMoveToXY(CurrentX, CurrentY)

            for i, key in options.targets
            {
				ScanType := key
				NovaFindClick(Format("targets\{1}.png", ScanType), scan.levels[key], "e n0 FuncHandle_Scan", FoundX, FoundY, AreaX1, AreaY1, AreaX2, AreaY2)          
            }
			
			CurrentX := CurrentX + MapStepX
	
		}
		
		CurrentX := CurrentX - MapStepX
		MapStepX := -MapStepX
		CurrentY := CurrentY - MapStepY
	}
	
	;MapMoveToXY(0, 0)
	;NovaMouseMove(WinCenterX, WinCenterY)
	
	; totals display
	Summuary := ""
	for i, key in options.targets
		Summuary .= Format("{1}:{2} ", key, ScanResult[key].Length())
		
	Log(Format("Scan summuary : {1}", Summuary))
	
	ScanResult["system"] := systemname
	ScanResult["timestamp"] := A_Now

	SaveScan(ScanResult)
	
    return ScanResult.Clone()
}

;*******************************************************************************
; Handle_Scan : Handle the collection of a single ressource
; ResX, ResY : Window coordinate of the location of the resource
;*******************************************************************************
Handle_Scan(ResX, ResY)
{
	global MainWinX, MainWinY
    global MainWinW, MainWinH
	global WinBorderX, WinBorderY
    global ScanResult, ScanType
    
	ResX := (ResX - MainWinX - WinBorderX - (MainWinW / 2)) + MapPosX 
	ResY := MapPosY - (ResY - MainWinY - WinBorderY - (MainWinH / 2))
	
	; check if it's not a dupplicate
	MaxDist := 25
	for i, res in ScanResult[ScanType]
	{
		if (Abs(ResX - res.x) < MaxDist) AND (Abs(ResY - res.y) < MaxDist)
		{
			return
		}
	}
	
    index:= ScanResult[ScanType].Length() + 1
    ScanResult[ScanType][index] :=[]
    ScanResult[ScanType][index].x := ResX
    ScanResult[ScanType][index].y := ResY
    
    Log(Format("Found a '{3}' at ({1:i},{2:i}), Total={4}", ResX, ResY, ScanType, ScanResult[ScanType].Length()))
}

;*******************************************************************************
; PeekClosestTarget : will peeks the closest target from the list to
; the given position
;*******************************************************************************
PeekClosestTarget(ByRef List, X, Y)
{
	FoundIndex := 0
	CurrentRes := 1
	MinDist := 99999999999999
	
	for i, target in List
	{
		DX := target.x - X
		DY := target.y - Y
		
		Dist := sqrt(DX*DX + DY*DY)
		
		
		if ((Dist < MinDist))
		{
			MinDist := Dist
			FoundIndex := i
		}
		
	}
	
	; remove ressource and return it
	if (FoundIndex> 0)
	{
		item := List[FoundIndex]
		List.RemoveAt(FoundIndex)
		return item
	}
	Else
		return ""
}

;*******************************************************************************
; PeekFurthestTarget : will peeks the furthest target from the list to
; the given position
;*******************************************************************************
PeekFurthestTarget(ByRef List, X, Y)
{
	FoundIndex := 0
	CurrentRes := 1
	MaxDist := 0
	
	for i, target in List
	{
		DX := target.x - X
		DY := target.y - Y
		
		Dist := sqrt(DX*DX + DY*DY)
		
		
		if ((Dist > MaxDist))
		{
			MaxDist := Dist
			FoundIndex := i
		}
		
	}
	
	; remove ressource and return it
	if (FoundIndex> 0)
	{
		item := List[FoundIndex]
		List.RemoveAt(FoundIndex)
		return item
	}
	Else
		return ""
}

SaveScan(scan)
{
	return SaveObjectToJSON(scan, Format("data\scans\{1}.json", scan["system"]))	
}

LoadScan(systemname)
{
	return GetObjectFromJSON(Format("data\scans\{1}.json", systemname))
}