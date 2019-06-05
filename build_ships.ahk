#include globals.ahk
#include utils.ahk


global Build_error := 0

;*******************************************************************************
; HandleFreeSlot : Handle the Filling of a free shipyard slot
; X, Y : Window coordinate of the location of the slot
;*******************************************************************************
HandleFreeSlot(X, Y)
{
    global FrigatesBuilt, FrigatesAmount
	global Build_error
	global FrigateType
    
	Log("Found a free slot at (" . X . "," . Y . ")")
	
	; open the slot
	NovaLeftMouseClick(X, Y)
	Sleep, 500
	
	; make sure frigates are selected on that shipyard
	if !NovaFindClick(Format("ships\{1}.png", FrigateType), 30, "w1000 n0")
	{
		Log("Could not find frigates as current ship, exiting.")
		return
	}
	
	; then click on build button
	if !NovaFindClick("buttons\build.png", 30, "w1000 n1")
	{
		Log("Could not find build button")
		Build_error := 1
	}
	Else
	{	
		; Add one more build to the counter
		FrigatesBuilt := FrigatesBuilt + 1
	}
		
	; then click on back button               
	while NovaFindClick("buttons\back_ships.png", 30, "w1000 n1")
	{
		Sleep, 1000
	}
	
	; wait to come back to main screen with economy button highlighted
	if !NovaFindClick("buttons\economy_on.png", 30, "w3000 n")
	{
		Log("Could not find economy tab, while getting back to main screen, exiting.")
		return
	}
	
	Log(Format("We queued ship {1} / {2}", FrigatesBuilt, FrigatesAmount))
	
}

;*******************************************************************************
; BuildFrigates : Will try to queue frigates until the amount is reached
; Amount : Number of frigates that should be built
;*******************************************************************************
BuildFrigates(Amount)
{
    global FrigatesBuilt
	global Build_error
	
	
    Build_error := 0
	
    if (Amount <= FrigatesBuilt)
    {
        Log("We already have built " . FrigatesBuilt . ", skipping for now.")
        return 1
    }
    
    ; popup the main menu
    if !PopRightMenu(1, "ECONOMY")
    {
        Log("ERROR : failed to popup main menu. exiting", 2)
        return 0
    }
    
	;Look for a free slots
	Loop, 5
	{
		Log("Checking available shipyards slots ...")
		while NovaFindClick("buttons\free_slot.png", 50, "n0 w1000 FuncHandleFreeSlot")
		{
			if (Build_error)
			{
				Log("ERROR : Build error was detected. exiting", 2)
				return 1
			}
			
			sleep, 500
			
			if (Amount <= FrigatesBuilt)
			{
				Log("We already have built " . FrigatesBuilt . ", skipping for now.")
				return 1
			}
		}
				
		; move mouse on top of shipyards
		NovaDragMouse(1073, 500, 0, -700)

		Log("Dragged down")
		;NovaMouseMove(1073, 906)
		;MouseClick, WheelDown,,, 1
		Sleep, 2000
	}
	
    ; Discard the main menu
    if !PopRightMenu(0)
    {
        Log("ERROR : failed to discard main menu. exiting", 2)
        return 0
    }
    
    return 1
}
