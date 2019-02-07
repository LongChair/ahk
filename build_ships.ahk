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
    
    ;Look for a free slot
    Search := 1
    DownCount := 0
    while Search and DownCount <= 2
    {
        Log("Looking for a free shipyard slot...")
        if WaitImage("buttons\free_slot.png", 540, 100, 976, 752, 2, FoundX, FoundY, 70)
        {
            Log("Found a free shipyard slot, clicking on it...")
            ; click on free slot
            NovaLeftMouseClick(FoundX + 20, FoundY + 20)
            
            ; make sure frigates are selected on that shipyard
            if !WaitImage("buttons\frigate.png",  6, 279, 201, 400, 2, FoundX, FoundY, 0)
            {
                Log("Could not find frigates as current ship, exiting.")
                return 0
            }
            
            ; then click on build button
            if !WaitImage("buttons\build.png", 951, 457, 1106, 520, 2, FoundX, FoundY, 0)
            {
                Log("Could not find build button, exiting.")
                return 0
            }
            
            ; click on build button
            Log("Clicking on shipyard slot...")
            NovaLeftMouseClick(FoundX + 20, FoundY + 20)
            sleep,1000
            
            FrigatesBuilt := FrigatesBuilt + 1
            
            ; then click on back button                
            if !WaitImage("buttons\back.png", 2, 48, 142, 103, 2, FoundX, FoundY, 0)
            {
                Log("Could not find back button, exiting.")
                return 0
            }
            
            Log("Clicking on back button...")
             ; click on back button
            NovaLeftMouseClick(FoundX + 20, FoundY + 20)
            
            ; wait for right menu to come back
            Log("Wait for right menu to come back...")
            if !WaitImage("buttons\economy_on.png",  921, 70, 1116, 215, 5, FoundX, FoundY, 30)
            {
                Log("Couldn't Find the economy button, exiting.")
                return 0
            }

        }
        else
        {
            Log("No more free slots found, scrolling down...")
            
            ; Scroll up to find eventual new shipyards slots
            DownCount := DownCount + 1
            
            ; move mouse on top of shipyards
            NovaMouseMove(680, 305)
            sleep, 500
            
            MouseClick, WheelDown,,, 1
            Sleep, 3000
        }
    }
    
    ; Discard the main menu
    if !PopRightMenu(0)
    {
        Log("ERROR : failed to discard main menu. exiting")
        return 0
    }
    
    return 1
}
