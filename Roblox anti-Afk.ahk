#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen

; GUI Setup
Gui, Font, s10
Gui, Add, GroupBox, x10 y10 w280 h190, Roblox Anti-AFK Controls
Gui, Add, Text, x20 y35 w70, Status:
Gui, Add, Text, vStatusText x95 y35 w175 cRed, Stopped
Gui, Add, Checkbox, vRandomKeys x20 y60 w260 Checked, Random movement keys (W,A,S,D)
Gui, Add, Checkbox, vRandomJump x20 y85 w260 Checked, Random jumping
Gui, Add, Checkbox, vRandomMouse x20 y110 w260 Checked, Random mouse movement
Gui, Add, Text, x20 y135 w85, Interval (sec):
Gui, Add, Edit, vInterval x110 y133 w50, 30
Gui, Add, UpDown, Range1-3600, 30
Gui, Add, Button, vToggleBtn gToggleAntiAFK x200 y133 w80 h25, Start
Gui, Add, Text, x20 y165 w240 vLastActionText, Last action: None
Gui, Add, StatusBar,, Ready to start. Click "Start" to begin anti-AFK

; Create system tray menu
Menu, Tray, NoStandard
Menu, Tray, Add, Show GUI, ShowGUI
Menu, Tray, Add, Exit, GuiClose
Menu, Tray, Default, Show GUI
Menu, Tray, Icon
Menu, Tray, Tip, Roblox Anti-AFK Tool

; Global variables
active := false
intervalMs := 30000

; Show the GUI
Gui, Show, w300 h240, Roblox Anti-AFK

return

ShowGUI:
    Gui, Show
return

ToggleAntiAFK:
    global active, intervalMs
    
    if (active) {
        active := false
        SetTimer, AntiAFK, Off
        GuiControl, +cRed, StatusText
        GuiControl,, StatusText, Stopped
        GuiControl,, ToggleBtn, Start
        SB_SetText("Anti-AFK disabled")
    } else {
        GuiControlGet, interval
        if interval is not number
        {
            MsgBox, 16, Error, Please enter a valid number for interval!
            return
        }
        
        if (interval < 1) {
            MsgBox, 16, Error, Interval must be at least 1 second!
            return
        }
        
        intervalMs := interval * 1000
        active := true
        SetTimer, AntiAFK, %intervalMs%
        GuiControl, +cGreen, StatusText
        GuiControl,, StatusText, Running
        GuiControl,, ToggleBtn, Stop
        SB_SetText("Anti-AFK enabled - Will run every " . interval . " seconds")
        
        ; Run once immediately
        Gosub, AntiAFK
    }
return

AntiAFK:
    if WinExist("ahk_class ROBLOX") {
        if WinActive("ahk_class ROBLOX") {
            SB_SetText("Performing anti-AFK actions...")
            
            ; Check which features are enabled
            GuiControlGet, RandomKeys
            GuiControlGet, RandomJump
            GuiControlGet, RandomMouse
            
            actionsTaken := 0
            
            ; Random movement keys
            if (RandomKeys) {
                Random, key, 1, 4
                If (key = 1)
                    Send, {w down}{w up}
                Else If (key = 2)
                    Send, {a down}{a up}
                Else If (key = 3)
                    Send, {s down}{s up}
                Else
                    Send, {d down}{d up}
                actionsTaken += 1
            }
            
            ; Random jumping
            if (RandomJump) {
                Random, jump, 1, 3
                If (jump = 1) {
                    Send, {Space}
                    actionsTaken += 1
                }
            }
            
            ; Random mouse movement
            if (RandomMouse) {
                MouseGetPos, xpos, ypos
                Random, move_x, -100, 100
                Random, move_y, -50, 50
                MouseMove, xpos + move_x, ypos + move_y, 5
                actionsTaken += 1
            }
            
            timeStamp := A_Hour . ":" . A_Min . ":" . A_Sec
            GuiControl,, LastActionText, Last action: %timeStamp% (%actionsTaken% actions)
            SB_SetText("Actions completed at " . timeStamp)
        } else {
            SB_SetText("Roblox window exists but is not active...")
        }
    } else {
        SB_SetText("Waiting for Roblox window to open...")
    }
return

; Close GUI handler
GuiClose:
GuiEscape:
    MsgBox, 4, Confirm Exit, Do you want to exit or minimize to tray?
    IfMsgBox, Yes
    {
        ExitApp
    }
    Else
    {
        Gui, Hide
        SB_SetText("Running in background. Right-click tray icon to restore.")
    }
return
