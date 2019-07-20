#include globals.ahk
#include utils.ahk

global PossibleRes := ["1k Allium", "2k Cristals", "10k experience", "20k energy", "20k Minerals", "100 CEG", "Turbo 3h", "Accel 50 percent", "Accel 100 percent", "10k energy", "500 allium", "10k minerals", "Turbo 1h", "1k Crystals"]
global FreeResCount := []

;*******************************************************************************
; IdentifyFreeResource : Grabs the name of the free resoure on screen
;*******************************************************************************
IdentifyFreeResource(ByRef description, Byref index)
{
	global PossibleRes
	
	for i, element in PossibleRes
	{
		if NovaFindClick("free_res\" . element . ".png", 30, "n0", FoundX, FoundY, 740, 350, 1040, 750)
		{
			description := element
			index := i
			return 1
		}
			
	}
	
	return 0
}

;*******************************************************************************
; ResetStats : Resets the global stats variable
;*******************************************************************************
ResetStats()
{
	global FreeResCollected, OtherResCollected
	global FreeResCount, PossibleRes
	global KilledCount

	FreeResCollected := 0
	OtherResCollected := 0
	for i, res in PossibleRes
	{
		FreeResCount[i] := 0
	}
	
	KilledCount := 0
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
		
		NovaEscapeClick()
	 
        ; reset all stats counters
        ResetStats()
        Sleep, 2000
		
        ; Now click on the return button
        if !NovaFindClick("buttons\back.png", 80, "w1000 n1")
        {
            Log("ERROR : Failed to click the back button for daily mission, exiting", 2)
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
 
 	; check if we have collected all the 32 free resources
	if (FreeResCollected >= MaxFreeRes)
	{
		Log(Format("All free ressources have been collected ({1}/{2}}), skipping ...", FreeResCollected, MaxFreeRes))
		return 1
	}

    ; Try to collect the free resources
    if NovaFindClick("buttons\free_ressources.png", 80, "n1", FoundX, FoundY, 200, 840, 600, 1050)
    {
        Log("Collecting free resources ... YEAH!")
        
		; Wait for the carte to show up
		if !NovaFindClick("buttons\crate.png", 50, "w2000 n0", FoundX, FoundY, 650, 300, 1150, 650)
		{
			Log("ERROR : Failed to find the crate, exiting", 2)
            return 0
		}
        
		; indentify what we got
		if !IdentifyFreeResource(ResDescription, ResIndex)
		{
			Log("ERROR : Could not retrieve free ressource information. exiting", 2)
		}
		
		FreeResCount[ResIndex] := FreeResCount[ResIndex] + 1
		
		Log("Collecting free resources ... got '" . ResDescription . "', YEAH!", 1)
		
		; Grab a screenshot of the resource
        ;NovaGrab(740, 350, 300, 365)
        ;Sleep, 1000
        
        ; look for the grab button
        Log("Clicking on grab button...")
        if !NovaFindClick("buttons\recuperer.png", 80, "w5000 n1", FoundX, FoundY, 500, 500, 1250, 880)
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
        
        ; click below the popup to make it vanish
        ; TODO : reworks here
        Log("Waiting for reward screen to get away ...")
        LoopCount := 0
        Loop
        {
			NovaFindClick("buttons\reward.png", 80, "w5000 n1")
			
            LoopCount := LoopCount + 1
            Sleep, 1000
        } Until WaitNovaScreen("STATION", 1) or LoopCount > 5
        
        if LoopCount > 5 
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
	if (NovaFindClick("buttons\help.png", 80, "w500 n1", FoundX, FoundY, 960, 900, 1040, 980))
	{
		Helped := Helped + 1
		Log(Format("Found People to help (Total {1})", Helped))
	}
    
    return 1
}