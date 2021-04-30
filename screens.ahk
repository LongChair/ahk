#include globals.ahk
#Include utils.ahk
#include libs\FindClick.ahk

;*******************************************************************************
; GetNovaScreen : identifies the current screen, the returned values can be :
;				  "SYSTEME", "GALAXIE", "STATION", "UNKNOWN"
;*******************************************************************************
GetNovaScreen()
{   
	if NovaFindClick("screen_markers\daily_mission.png", 30, "n0", FoundX, FoundY, 205, 900, 350, 1065)
		return "STATION"
	
	if NovaFindClick("screen_markers\galaxy_qmark.png", 30, "n0", FoundX, FoundY, 20, 920, 135, 1065)
		return "GALAXIE"
	
	if NovaFindClick("screen_markers\my_station.png", 30, "n0", FoundX, FoundY, 270, 845, 425, 990)
		return "SYSTEME"
	
    return "UNKNOWN"
}

;*******************************************************************************
; WaitNovaScreen : Wait for a given screen name values can be :
;				  "SYSTEME", "GALAXIE", "STATION", "UNKNOWN"
; Function will loop until any of those 
;*******************************************************************************
WaitNovaScreen(Screen, Timeout)
{
    Remaining := Timeout
    
	Log("Waiting For nova Screen " . Screen . " to show up...")
	While (GetNovaScreen() != Screen) AND (Remaining > 0)
    {
		sleep, 100
        Remaining := Remaining - 0.1
    }
    
    if (Remaining > 0)
    {
        Log("Screen "  . Screen . " is up.")
		Sleep, 500
        return 1
    }
    else
    {
        Log("ERROR : Timeout while waiting screen " . Screen . " Exceeded " . Timeout . " seconds", 2)
        return 0
    }
}

;*******************************************************************************
; GotoScreen : Goes to the given screen, values can be 
;				  "SYSTEME", "GALAXIE", "STATION"
;*******************************************************************************
GotoScreen(TargetScreen, Timeout)
{
    CurrentScreen := "UNKNOWN"
    WaitTargetScreen := 0
    Remaining := Timeout
    
	; Wait to have a known screen
	Log("Identifying screen ...")
    
    While (CurrentScreen = "UNKNOWN") AND (Remaining > 0)
    {
		CurrentScreen := GetNovaScreen() 
        Sleep, 100
        Remaining := Remaining - 0.1
    }
    
    if (Remaining <= 0)
    {
        LOG("ERROR : Timeout while trying to identify screen for move to " . TargetScreen . " after " . Timeout . " seconds", 2)
        return 0
    }
	
    Log("Asking to go from " . CurrentScreen . " to " . TargetScreen)
	
	; Source screen is STATION
    If (CurrentScreen = "STATION")
    {
        If (TargetScreen = "SYSTEME")
        {
            NovaLeftMouseClick(1520, 950)
            WaitTargetScreen := 1
        }
        If (TargetScreen = "GALAXIE")
        {
            NovaLeftMouseClick(1740, 950)
            WaitTargetScreen := 1
        }
    }
	
	; Source screen is GALAXIE
    If (CurrentScreen = "GALAXIE")
    {
        If (TargetScreen = "SYSTEME")
        {
            NovaLeftMouseClick(1520, 950)
            WaitTargetScreen := 1
        }
        If (TargetScreen = "STATION")
        {
            NovaLeftMouseClick(1740, 950)
            WaitTargetScreen := 1
        }
    }
	
	; Source screen is SYSTEME
    If (CurrentScreen = "SYSTEME")
    {
        If (TargetScreen = "GALAXIE")
        {
             NovaLeftMouseClick(1520, 950)
            Sleep, 10
            WaitTargetScreen := 1
        }
        If (TargetScreen = "STATION")
        {
            NovaLeftMouseClick(1740, 950)
            Sleep, 10
            WaitTargetScreen := 1
        }
    }
	
	; Now wait for target screen
    If (WaitTargetScreen)
    {
        if !WaitNovaScreen(TargetScreen, Timeout)
        {
             return 0
        }
    }

	
    Log("Navigation Complete.")
    return 1
}