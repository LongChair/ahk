#Include utils.ahk
#include libs\FindClick.ahk

;*******************************************************************************
; GetNovaScreen : identifies the current screen, the returned values can be :
;				  "SYSTEME", "GALAXIE", "STATION", "UNKNOWN"
;*******************************************************************************
GetNovaScreen()
{
    global
    
	if NovaFindClick("screen_markers\daily_mission.png", 20, "w100 n0")
		return "STATION"
	
	if NovaFindClick("screen_markers\galaxy_qmark.png", 20, "w100 n0")
		return "GALAXIE"
	
	if NovaFindClick("screen_markers\my_station.png", 20, "w100 n0")
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
    global
    local Remaining := Timeout
	Log("Waiting For nova Screen " . Screen . " to show up...")
	While (GetNovaScreen() != Screen) AND (Remaining > 0)
    {
		sleep, 500
        Remaining := Remaining - 0.5
    }
    
    if (Remaining > 0)
    {
        Log("Screen "  . Screen . " is up.")
        return 1
    }
    else
    {
        Log("ERROR : Timeout while waiting screen " . Screen . " Exceeded " . Timeout . " seconds")
        return 0
    }
}

;*******************************************************************************
; GotoScreen : Goes to the given screen, values can be 
;				  "SYSTEME", "GALAXIE", "STATION"
;*******************************************************************************
GotoScreen(TargetScreen, Timeout)
{
    global
    local CurrentScreen := "UNKNOWN", WaitTargetScreen := 0
    local Remaining := Timeout
    
	; Wait to have a known screen
	Log("Identifying screen ...")
    sleep, 500
    
    While (CurrentScreen = "UNKNOWN") AND (Remaining > 0)
    {
		CurrentScreen := GetNovaScreen() 
        Sleep, 500
        Remaining := Remaining - 0.5
    }
    
    if (Remaining <= 0)
    {
        LOG("ERROR : Timeout while trying to identify screen for move to " . TargetScreen . " after " . Timeout . " seconds")
        return 0
    }
	
    Log("Asking to go from " . CurrentScreen . " to " . TargetScreen)
	
	; Source screen is STATION
    If (CurrentScreen = "STATION")
    {
        If (TargetScreen = "SYSTEME")
        {
            NovaLeftMouseClick(923, 591)
            WaitTargetScreen := 1
        }
        If (TargetScreen = "GALAXIE")
        {
            NovaLeftMouseClick(1051, 591)
            WaitTargetScreen := 1
        }
    }
	
	; Source screen is GALAXIE
    If (CurrentScreen = "GALAXIE")
    {
        If (TargetScreen = "SYSTEME")
        {
            NovaLeftMouseClick(919, 591)
            WaitTargetScreen := 1
        }
        If (TargetScreen = "STATION")
        {
            NovaLeftMouseClick(1058, 591)
            WaitTargetScreen := 1
        }
    }
	
	; Source screen is SYSTEME
    If (CurrentScreen = "SYSTEME")
    {
        If (TargetScreen = "GALAXIE")
        {
            NovaLeftMouseClick(925, 595)
            Sleep, 10
            WaitTargetScreen := 1
        }
        If (TargetScreen = "STATION")
        {
            NovaLeftMouseClick(1051, 591)
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