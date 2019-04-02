#include globals.ahk
#include utils.ahk



;*******************************************************************************
; HandleFreeSlot : Handle the Filling of a free shipyard slot
; X, Y : Window coordinate of the location of the slot
;*******************************************************************************
HandleFreeSlot(X, Y)
{
    global FrigatesBuilt
    
	Log("Found a free slot at (" . X . "," . Y . ")")
	
	; open the slot
	NovaLeftMouseClick(X, Y)
	Sleep, 500
	
	; make sure frigates are selected on that shipyard
	if !NovaFindClick("buttons\frigate.png", 30, "w1000 n0")
	{
		Log("Could not find frigates as current ship, exiting.")
		return
	}
	
	; then click on build button
	if !NovaFindClick("buttons\build.png", 30, "w1000 n1")
	{
		Log("Could not find build button, exiting.")
		return
	}
	
	; Add one more build to the counter
	FrigatesBuilt := FrigatesBuilt + 1
	
	; then click on back button               
	if !NovaFindClick("buttons\back_ships.png", 30, "w1000 n1")
	{
		Log("Could not find back button, exiting.")
		return
	}
	
	; wait to come back to main screen with economy button highlighted
	if !NovaFindClick("buttons\economy_on.png", 30, "w3000 n")
	{
		Log("Could not find economy tab, while getting back to main screen, exiting.")
		return
	}
	
}

;*******************************************************************************
; BuildFrigates : Will try to queue frigates until the amount is reached
; Amount : Number of frigates that should be built
;*******************************************************************************
BuildFrigates(Amount)
{
    global FrigatesBuilt
    
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
	Loop, 3
	{
		Log("Checking available shipyards slots ...")
		while NovaFindClick("buttons\free_slot.png", 80, "n0 w1000 FuncHandleFreeSlot")
		{
			sleep, 2000
		}
				
		; move mouse on top of shipyards
		NovaMouseMove(1050, 470)
		sleep, 500

		MouseClick, WheelDown,,, 1
		Sleep, 3000
	}
	
    ; Discard the main menu
    if !PopRightMenu(0)
    {
        Log("ERROR : failed to discard main menu. exiting", 2)
        return 0
    }
    
    return 1
}
