; script version
global Version := "5.0"

; Working directory
global BlueStacksPath := "C:\ProgramData\BlueStacks\Client\Bluestacks.exe"

; Loop time and activation
global LoopTime := 0
global Farming := 0
global IterationTime := 0
    
; Window Size
global AppW := 1920
global AppH := 1080

; Window Position
global AppX := 0
global AppY := 0

; free resources collected
global FreeResCollected := 0
global MaxFreeRes := 30

; regular free collected
global OtherResCollected := 0

; Frigates amount to build
global FrigatesAmount := 0
global FrigatesBuilt := 0

global NumFreeMecas := 0
global StartFreeMecas := 0

; Pastebin credentials
global PasteBinUser := ""
global PasteBinPassword := ""
global PasteBinConfig := ""

;General information
global PlayerName := ""
global CommandLine := ""
global WindowName := ""
global MaxPlayerMecas := 6
global MaxPlayerFleets := 6
global KilledCount := 0
global CurrentSystem := ""
global FrigateType =""

global Window_ID := 0

global ResPriority1 := ""
global ResPriority2 := ""
global ResPriority3 := ""

global StationX := 0
global StationY := 0

global LastStartTime := 0

; blacklists
global Ressources_BlackList := []
global Pirates_BlackList := []

; various global counters for callbacks
global IdleCounter := 0

global RssDistThreshold := 15

; program loop period in s
Global LoopPeriod := 6 * 60 + 30

; Amount of people helped
global Helped := 0

