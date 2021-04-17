#include globals.ahk
#include utils.ahk

;*******************************************************************************
; BuildShips : Will try to queue frigates until the amount is reached
; Amount : Number of frigates that should be built
;*******************************************************************************
BuildShips(Amount)
{
    global FrigatesBuilt, FrigatesAmount
	global Build_error
	global FrigateType
	
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
		while NovaFindClick("buttons\free_slot.png", 50, "w1000 n1", FoundX, FoundY, 830, 130, 1435, 950)
		{
        
            ; make sure frigates are selected on that shipyard
            if (!NovaFindClick(Format("ships\{1}.png", FrigateType), 30, "w3000 n0"))
            {
                Log("ERROR : Could not find frigates as current ship, exiting.")
                return 0
            }
            
            ; then click on build button
            while (NovaFindClick("buttons\build_ships.png", 20, "w1000 n1", FoundX, FoundY, 1550, 710, 1850, 850))
            {
                FrigatesBuilt := FrigatesBuilt + 1
                Log(Format("We queued ship {1} / {2}", FrigatesBuilt, FrigatesAmount))
                Sleep, 500
            }
            
            ; then click on back button               
            while NovaFindClick("buttons\back_ships.png", 50, "w500 n1", FoundX, FoundY, 0, 40, 210, 160)
            {
                Log("Going back from shipyard screen...")
            }
            
            ; wait to come back to main screen with economy button highlighted
            if !NovaFindClick("buttons\economy_on.png", 30, "w3000 n0", FoundX, FoundY, 1510, 170, 1800, 270)
            {
                Log("ERROR : Could not find economy tab, while getting back to main screen, exiting.")
                return 0
            }    
			
			if (Amount <= FrigatesBuilt)
			{
				Log("We already have built " . FrigatesBuilt . ", skipping for now.")
				return 1
			}
		}
				
		; move mouse on top of shipyards
		NovaDragMouse(1073, 500, 0, -700, 50)
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