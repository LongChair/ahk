#include utils.ahk

;*******************************************************************************
; PopRightMenu : Will pop the main right menu
; Visible : 1 = Show it, 0 = Close it
;*******************************************************************************
PopRightMenu(Visible)
{
    global
    
    if (Visible)
    {
        Log("Showing Main right menu ...")
        ; click the button to show up the menu
        NovaLeftMouseClick(1083, 339)
        Sleep, 500
        
        ; wait for eventual unselected economy tab
        if NovaFindClick("buttons\economy_off.png", 30, "w1000 n1")
        {
            Log("Selected economy tab in right menu")
        }
        
        if !NovaFindClick("buttons\economy_on.png", 30, "w1000 n0")
        {
            Log("ERROR : Could not ind the economy button, exiting.")
            return 0
        }
        
        ; we found button, that's done
        return 1
        
    }
    else
    {
        Log("Hiding Main right menu ...")
        
        ; click to close teh menu
        NovaEscapeClick()
        
        ; make sure we don't have the menu bar again
        ; For this we check if we find the CEG icon which is behind
        if !NovaFindClick("buttons\ceg.png", 30, "w10000 n0")
        {
            Log("ERROR : Timeout for menu bar to disappear, exceeded 10 seconds.")
            return 0
        }
        
        return 1
    }
}

;*******************************************************************************
; HandleFreeSlot : Handle the Filling of a free shipyard slot
; X, Y : Window coordinate of the location of the slot
;*******************************************************************************
HandleFreeSlot(X, Y)
{
	Log("Found a free slot at (" . X . "," . Y . ")")
	
	; open the slot
	NovaLeftMouseClick(X, Y)
	Sleep, 500
	
	; make sure frigates are selected on that shipyard
	if !NovaFindClick("buttons\frigate.png", 0, "w1000 n0")
	{
		Log("Could not find frigates as current ship, exiting.")
		return 0
	}
	
	; then click on build button
	if !NovaFindClick("buttons\build.png", 0, "w1000 n1")
	{
		Log("Could not find build button, exiting.")
		return 0
	}
	
	; Add one more build to the counter
	FrigatesBuilt := FrigatesBuilt + 1
	
	; then click on back button               
	if !NovaFindClick("buttons\back.png", 0, "w1000 n1")
	{
		Log("Could not find back button, exiting.")
		return 0
	}
	
	; wait to come back to main screen with economy button highlighted
	if !NovaFindClick("buttons\economy_on.png", 0, "w3000 n")
	{
		Log("Could not find economy tab, while getting back to main screen, exiting.")
		return 0
	}
	
	
	return 1
}

;*******************************************************************************
; BuildFrigates : Will try to queue frigates until the amount is reached
; Amount : Number of frigates that should be built
;*******************************************************************************
BuildFrigates(Amount)
{
    global
    if (Amount <= FrigatesBuilt)
    {
        Log("We already have built " . FrigatesBuilt . ", skipping for now.")
        return 1
    }
    
    ; popup the main menu
    if !PopRightMenu(1)
    {
        Log("ERROR : failed to popup main menu. exiting")
        return 0
    }
    
	;Look for a free slots
	Loop, 3
	{
		Log("Checking available shipyards slots ...")
		ResCount := NovaFindClick("buttons\free_slot.png", 80, "e n0 w1000 FuncHandleResource")
		
		Log("Found " . ResCount . " free slots, Scrolling down ...")
		
		; move mouse on top of shipyards
		NovaMouseMove(680, 305)
		sleep, 500

		MouseClick, WheelDown,,, 1
		Sleep, 3000
	}
	
    ; Discard the main menu
    if !PopRightMenu(0)
    {
        Log("ERROR : failed to discard main menu. exiting")
        return 0
    }
    
    return 1
}
