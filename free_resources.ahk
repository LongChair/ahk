#include globals.ahk
#include utils.ahk

global FreeResCount := []

;*******************************************************************************
; ResetStats : Resets the global stats variable
;*******************************************************************************
ResetStats()
{
	global FreeResCollected, OtherResCollected
	global FreeResCount, PossibleRes
	global KilledCount
	global EliteKill

	FreeResCollected := 0
	OtherResCollected := 0
	KilledCount := 0
	EliteKill := 0
	Helped := 0
}

;*******************************************************************************
; CheckFreeResources : Checks and grabs free ressources
;*******************************************************************************
CheckFreeResources()
{   
    global FreeResCollected, MaxFreeRes
    
    ; Go into space station screen 
    Log("Checking free resources ...")
    if !GotoScreen("STATION", 60)
    {
        return 0
    }
	
    ; Look daily mission icon 
    if NovaFindClick("buttons\day_1.png", 30, "n1", FoundX, FoundY, 200, 840, 600, 1050)
    {
        Log("Found Day 1 icon, and clicked.")
     
		 ; look for the reward screen
        if !NovaFindClick("buttons\reward_Connexion.png", 30, "w5000 n1")
        {
            Log("ERROR : Failed to find the reward connexion button for daily mission, exiting", 2)
            return 0
        }
		
		 ; look for the reward screen
        if !NovaFindClick("buttons\reward.png", 30, "w5000 n1")
        {
            Log("ERROR : Failed to find the reward screen for daily mission, exiting", 2)
            return 0
        }
		
		Sleep, 1000
		NovaEscapeClick()
	 
        ; reset all stats counters
        ResetStats()
        Sleep, 2000
		

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
    if NovaFindClick("buttons\free_ressources.png", 80, "n1", FoundX, FoundY, 200, 840, 600, 1050)
    {     
		; Wait for the carte to show up
		if !NovaFindClick("buttons\crate.png", 50, "w2000 n0", FoundX, FoundY, 850, 300, 1150, 650)
		{
			Log("ERROR : Failed to find the crate, maybe we have completed all daylies", 2)
            return 1
		}
    	
		Log("Collecting free resources ... YEAH!", 1)
		
	    ; look for the grab button
        Log("Clicking on grab button...")
        if !NovaFindClick("buttons\recuperer.png", 80, "w5000 n1", FoundX, FoundY, 800, 800, 1250, 1000)
        {
            Log("ERROR : Failed to click the grab button for free resources, exiting", 2)
            return 0
        }
        
		FreeResCollected := FreeResCollected + 1
		
        Log("Waiting for reward screen...")
        if !NovaFindClick("buttons\reward.png", 80, "w5000 n1")
        {
            Log("ERROR : Failed to click the reward button for free resources, could be that we got them all ?", 2)
        }
		Else
		{
			SendDiscord(":candy: Collected free ressource.")
		}
                
        if (!WaitNovaScreen("STATION", 1))
        {
            Log("ERROR : Timeout waiting for station screen, stopping", 2)
            return 0
        }
		
	
    }
	Else
    {
        Log("No free resources :/")
    }
	
	; check for help
	if (NovaFindClick("buttons\help.png", 30, "w500 n1", FoundX, FoundY, 960, 900, 1100, 1035))
	{
		Helped := Helped + 1
		Log(Format("Found People to help (Total {1})", Helped))
	}
    
    return 1
}