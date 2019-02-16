; script version
global Version := "4.0"

; Working directory
global BlueStacksPath := "C:\ProgramData\BlueStacks\Client\Bluestacks.exe"

; Loop time and activation
global LoopTime := 0
    
; Window Size
global AppW := 1920
global AppH := 1080

; Window Position
global AppX := 0
global AppY := 0

; free resources collected
global FreeResCollected := 0
global MaxFreeRes := 32

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