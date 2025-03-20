#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen

; GUI Setup
Gui, Font, s10
Gui, Add, GroupBox, x10 y10 w320 h325, Anti-AFK Controls

; Status display
Gui, Add, Text, x20 y35 w70, Status:
Gui, Add, Text, vStatusText x95 y35 w225 cRed, Stopped

; Action options
Gui, Add, Checkbox, vRandomKeys x20 y60 w300 Checked, Random movement keys (W,A,S,D)
Gui, Add, Checkbox, vRandomJump x20 y85 w300 Checked, Random jumping
Gui, Add, Checkbox, vRandomMouse x20 y110 w300 Checked, Random mouse movement

; Timing settings
Gui, Add, Text, x20 y135 w120, Interval (sec):
Gui, Add, Edit, vInterval x150 y133 w50, 30
Gui, Add, UpDown, Range1-3600, 30
Gui, Add, Button, vToggleBtn gToggleAntiAFK x230 y133 w90 h25, Start

; Last action display
Gui, Add, Text, x20 y165 w290 vLastActionText, Last action: None

; User input detection settings - repositioned for better spacing
Gui, Add, Checkbox, vUserInputPause x20 y190 w300 Checked, Pause when user input detected

; Initial delay setting
Gui, Add, Text, x20 y215 w120, Initial delay (sec):
Gui, Add, Edit, vInitialDelay x150 y213 w50, 10
Gui, Add, UpDown, Range0-600, 10

; Resume delay setting
Gui, Add, Text, x20 y240 w120, Resume after (sec):
Gui, Add, Edit, vResumeDelay x150 y238 w50, 15
Gui, Add, UpDown, Range5-600, 15

; Roblox window setting - simplified to just a checkbox
Gui, Add, Checkbox, vFocusRoblox x20 y265 w300 Checked, Focus Roblox window on resume

; Input status display
Gui, Add, Text, x20 y290 w290 vInputStatusText, Input detection: Not active

; Status bar
Gui, Add, StatusBar,, Ready to start. Click "Start" to begin anti-AFK

; Create system tray menu
Menu, Tray, NoStandard
Menu, Tray, Add, Show GUI, ShowGUI
Menu, Tray, Add, Exit, GuiClose
Menu, Tray, Default, Show GUI
Menu, Tray, Icon
Menu, Tray, Tip, Anti-AFK Tool

; Global variables
active := false
paused := false
inputMonitoringActive := false
intervalMs := 30000
initialDelayMs := 10000
resumeDelayMs := 15000
lastInputTime := A_TickCount
userIsActive := false
robloxFocused := false  ; Variable to track focus success

; Show the GUI - reduced height since we removed an option
Gui, Show, w340 h385, Anti-AFK Tool

return

ShowGUI:
    Gui, Show
return

ToggleAntiAFK:
    global active, intervalMs, resumeDelayMs, initialDelayMs, inputMonitoringActive
    
    if (active) {
        active := false
        inputMonitoringActive := false
        SetTimer, AntiAFK, Off
        SetTimer, CheckUserInput, Off
        SetTimer, StartInputMonitoring, Off
        GuiControl, +cRed, StatusText
        GuiControl,, StatusText, Stopped
        GuiControl,, ToggleBtn, Start
        GuiControl,, InputStatusText, Input detection: Not active
        SB_SetText("Anti-AFK disabled")
    } else {
        GuiControlGet, interval
        GuiControlGet, resumeDelay
        GuiControlGet, initialDelay
        
        if (interval is not number) || (resumeDelay is not number) || (initialDelay is not number)
        {
            MsgBox, 16, Error, Please enter valid numbers for all intervals!
            return
        }
        
        if (interval < 1) {
            MsgBox, 16, Error, Interval must be at least 1 second!
            return
        }
        
        if (resumeDelay < 5) {
            MsgBox, 16, Error, Resume delay must be at least 5 seconds!
            return
        }
        
        intervalMs := interval * 1000
        resumeDelayMs := resumeDelay * 1000
        initialDelayMs := initialDelay * 1000
        active := true
        paused := false
        inputMonitoringActive := false
        userIsActive := false
        lastInputTime := A_TickCount
        
        ; Start the anti-AFK timer immediately
        SetTimer, AntiAFK, %intervalMs%
        
        ; Set up delayed start for user input monitoring
        if (initialDelay > 0) {
            GuiControl,, InputStatusText, Input detection: Starting in %initialDelay%s
            SetTimer, StartInputMonitoring, %initialDelayMs%
        } else {
            inputMonitoringActive := true
            GuiControl,, InputStatusText, Input detection: Active
            SetTimer, CheckUserInput, 1000  ; Check for user input every second
        }
        
        GuiControl, +cGreen, StatusText
        GuiControl,, StatusText, Running
        GuiControl,, ToggleBtn, Stop
        SB_SetText("Anti-AFK enabled - Will run every " . interval . " seconds")
        
        ; Run once immediately
        Gosub, AntiAFK
    }
return

; Start input monitoring after initial delay
StartInputMonitoring:
    SetTimer, StartInputMonitoring, Off
    inputMonitoringActive := true
    GuiControl,, InputStatusText, Input detection: Active
    SetTimer, CheckUserInput, 1000
    SB_SetText("User input monitoring now active")
return

; Focus the Roblox window - simplified to only use process name
FocusRobloxWindow:
    global robloxFocused
    robloxFocused := false
    
    GuiControlGet, FocusRoblox
    if (!FocusRoblox)
        return
        
    ; Try to find and activate the Roblox window by process name only
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate
        SB_SetText("Activated Roblox window")
        robloxFocused := true
    }
    else {
        SB_SetText("Could not find Roblox window")
    }
return

; Monitor user input (keyboard and mouse)
CheckUserInput:
    if (!active || !inputMonitoringActive)
        return
    
    GuiControlGet, UserInputPause
    if (!UserInputPause)
        return
    
    ; Get the idle time (time since last input)
    idleTime := A_TimeIdlePhysical
    
    if (idleTime < 1000) {  ; User provided input in the last second
        if (!userIsActive) {
            userIsActive := true
            paused := true
            lastInputTime := A_TickCount
            GuiControl,, StatusText, Paused (User Active)
            SB_SetText("User activity detected - Paused anti-AFK")
        } else {
            ; Update the last input time
            lastInputTime := A_TickCount
        }
    } else if (userIsActive) {
        ; Check if we should resume after user inactivity
        timeSinceInput := A_TickCount - lastInputTime
        if (timeSinceInput >= resumeDelayMs) {
            userIsActive := false
            paused := false
            
            ; Focus Roblox window when resuming
            Gosub, FocusRobloxWindow
            
            GuiControl,, StatusText, Running
            SB_SetText("Resuming after " . resumeDelay . " seconds of inactivity")
        } else {
            ; Update status with countdown
            remainingSecs := Floor((resumeDelayMs - timeSinceInput) / 1000)
            GuiControl,, StatusText, Paused (Resume in: %remainingSecs%s)
        }
    }
return

AntiAFK:
    ; Skip if we're paused due to user activity
    if (paused)
        return
    
    ; Try to focus the Roblox window before performing actions
    Gosub, FocusRobloxWindow
        
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
