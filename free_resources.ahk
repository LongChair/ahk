#include utils.ahk

;*******************************************************************************
; CheckFreeResources : Checks and grabs free ressources
;*******************************************************************************
CheckFreeResources()
{   
    global
    ; Go into space station screen 
    Log("Checking free resources ...")
    if !GotoScreen("STATION", 60)
    {
        return 0
    }
	
    ; Look daily mission icon 
    if NovaFindClick("buttons\day_1.png", 80, "w1000 n1")
    {
        Log("Found Day 1 icon, and clicked.")
     
        ; look for the grab button
        if !NovaFindClick("buttons\recuperer.png", 80, "w1000 n1")
        {
            Log("ERROR : Failed to click the grab button for daily mission, exiting")
            return 0
        }
        
        ; reset free resources counter
        FreeResCollected := 0
        
        ; Now click on the return button
        if !NovaFindClick("buttons\back.png", 80, "w1000 n1")
        {
            Log("ERROR : Failed to click the back button, exiting")
            return 0
        }
        
        Log("Waiting to return to station screen ...")
        if !WaitNovaScreen("STATION", 10)
        {
            return 0
        }
    }
    else
    {
        Log("No Day 1 button found, checking free resources")
    }
 
    ; Try to collect the free resources
    if NovaFindClick("buttons\free_ressources.png", 80, "w1000 n1")
    {
        Log("Collecting resources ... YEAH!")
        MajorLog("Collecting resources ... YEAH!")
        
        ; Grab a screenshot of the resource
        NovaGrab(443, 244, 250, 230)
        Sleep, 1000
        
        ; look for the grab button
        Log("Clicking on grab button...")
        if !NovaFindClick("buttons\recuperer.png", 80, "w1000 n1")
        {
            Log("ERROR : Failed to click the grab button for free resources, exiting")
            return 0
        }
        
        Log("Waiting for reward screen...")
        if !NovaFindClick("buttons\reward.png", 80, "w2000 n1")
        {
            Log("ERROR : Failed to click the grab button for free resources, exiting")
            return 0
        }
        
        ; click below the popup to make it vanish
        ; TODO : reworks here
        Log("Waiting for reward screen to get away ...")
        LoopCount := 0
        Loop
        {
            LoopCount := LoopCount + 1
            Sleep, 1000
        } Until WaitNovaScreen("STATION", 1) or LoopCount > 5
        
        if LoopCount > 5 
        {
            Log("ERROR : Timeout waiting for station screen, stopping")
            return 0
        }
    }
	Else
    {
        Log("No free resources :/")
    }
    
    return 1
}