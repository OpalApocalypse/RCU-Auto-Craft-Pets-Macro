#NoEnv
#SingleInstance Force
#MaxThreadsPerHotkey 2
Thread, Interrupt, 1    ; allow hotkeys to interrupt running threads so Pause/Stop are responsive

if !A_IsAdmin
{
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
}

SendMode Event
SetBatchLines, -1
SetMouseDelay, -1
SetKeyDelay, -1, -1
CoordMode, Mouse, Client
CoordMode, Pixel, Client
SetTitleMatchMode, 2

; ---------------------------
; Globals / Config
; ---------------------------
global WindowWidth := 800
global WindowHeight := 600
global robloxExe := "RobloxPlayerBeta.exe"
global STOP := false
global PAUSED := false
global CraftMode := ""
global SelectorSubmitted := false
global SwitchingMode := false
global MergeAllRequested := false
global CraftAllMode := false  ; NEW: mode selector

global PetTypeFilter := ""    ; Holds the text for the currently selected pet filter

; Debounce helper for F2 (declare as global so the hotkey label can use it)
global lastF2 := 0

; For internal tracking, not used for logic anymore
global lastCraftUsed := ""

; Debug logging (toggle)
global DEBUG := true                      ; set to false to disable logging
global DEBUG_LOG := A_ScriptDir "\rcu_click_debug.log"

if (DEBUG)
{
    FileDelete, %DEBUG_LOG%
    FileAppend, % A_Now " - Debug log started`n", %DEBUG_LOG%
}

;
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; 			Made by Opal (Cinnamowopal)
;	 			  N0NG Clan (duh)
; https://www.roblox.com/users/109818/profile
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;

; ---------------------------
; F1 - Start / choose mode
; ---------------------------
F1::
if (SwitchingMode)
    return

Gosub, ShowModeSelector
if (CraftMode = "")
    return

STOP := false
PAUSED := false
Gosub, ActivateRoblox

if !EnsureRemoteOpen()
    return

Gosub, PrepareMode
Gosub, MainLoop
return

; ---------------------------
; F2 - Pause / Unpause (with debounce)
; ---------------------------
F2::
if (SwitchingMode)
    return

; Debounce rapid toggles so accidental spamming doesn't immediately flip state repeatedly.
debounceMs := 300
if (A_TickCount - lastF2 < debounceMs)
    return
lastF2 := A_TickCount

PAUSED := !PAUSED
ToolTip, % PAUSED ? "Paused" : "Running"
SetTimer, RemoveToolTip, -800
return

; ---------------------------
; F3 - Switch mode
; ---------------------------
F3::
if (SwitchingMode)
    return

SwitchingMode := true
STOP := true
PAUSED := false
ToolTip, Switching mode...
SetTimer, RemoveToolTip, -800
Sleep, 250

Gosub, ShowModeSelector
if (CraftMode = "")
{
    SwitchingMode := false
    return
}

WinActivate, ahk_exe %robloxExe%
WinWaitActive, ahk_exe %robloxExe%,, 2
Sleep, 400

CloseOpenPanel()
Sleep, 300

if !EnsureRemoteOpen()
{
    SwitchingMode := false
    return
}

STOP := false
PAUSED := false
SwitchingMode := false
Gosub, PrepareMode
Gosub, MainLoop
return

; ---------------------------
; F4 - Exit script
; ---------------------------
F4::
ExitApp

; ---------------------------
; Activate / resize Roblox
; ---------------------------
ActivateRoblox:
WinActivate, ahk_exe %robloxExe%
WinWaitActive, ahk_exe %robloxExe%,, 2
if ErrorLevel
{
    MsgBox, 48, Error, Could not activate Roblox window.
    return
}

WinMove, ahk_exe %robloxExe%,, 100, 100, %WindowWidth%, %WindowHeight%
Sleep, 700

WinActivate, ahk_exe %robloxExe%
WinWaitActive, ahk_exe %robloxExe%,, 2
if ErrorLevel
{
    MsgBox, 48, Error, Roblox window lost focus.
    return
}
return

; ---------------------------
; GUI selector WITH Merge All Option + PetType filters
; ---------------------------
ShowModeSelector:
SelectorSubmitted := false

Gui, ModeSelect:Destroy
Gui, ModeSelect:New, +AlwaysOnTop +ToolWindow, Craft Mode

; --- LEFT COLUMN ---
Gui, Font, s12, Segoe UI Bold
Gui, Add, Text, x57 y17 w115 Center, Craft ALL Pets

Gui, Font, s10, Segoe UI
Gui, Add, Progress, x55 y42 w120 h3 -Smooth cBlack, 100

Gui, Font, s8, Segoe UI
Gui, Add, Text, x45 y55 w140 Center, Crafts all pets at once.
Gui, Add, Text, x45 y68 w140 Center, Good for XP.

Gui, Font, s10, Segoe UI
Gui, Add, Button, x65 y98 w100 h27 gSelectCraftAll, All Types
Gui, Add, Button, x14 y132 w62 h28 gSelectGoldenAll, Golden
Gui, Add, Button, x84 y132 w62 h28 gSelectToxicAll, Toxic
Gui, Add, Button, x154 y132 w62 h28 gSelectGalaxyAll, Galaxy

; --- RIGHT COLUMN ---
Gui, Font, s12, Segoe UI Bold
Gui, Add, Text, x287 y17 w115 Center, Craft 1-by-1

Gui, Font, s10, Segoe UI
Gui, Add, Progress, x285 y42 w120 h3 -Smooth cBlack, 100

Gui, Font, s8, Segoe UI
Gui, Add, Text, x275 y55 w140 Center, Crafts one pet at a time.
Gui, Add, Text, x275 y68 w140 Center, Better Shiny chance.

Gui, Font, s10, Segoe UI
Gui, Add, Button, x295 y98 w100 h27 gSelectMergeAll, All Types
Gui, Add, Button, x244 y132 w62 h28 gSelectGolden, Golden
Gui, Add, Button, x314 y132 w62 h28 gSelectToxic, Toxic
Gui, Add, Button, x384 y132 w62 h28 gSelectGalaxy, Galaxy

; --- Vertical Center Line (cuts off below buttons) ---
Gui, Add, Progress, x229 y10 w3 h162 -Smooth cBlack, 100
; --- Horizontal Line Across the Bottom ---
Gui, Add, Progress, x0 y180 w460 h3 -Smooth cBlack, 100

; --------- NEW FILTER SECTION ----------
Gui, Font, s8, Segoe UI Bold
Gui, Add, Text, x10 y195 w220 , Only Craft the Checked Types:
Gui, Font, s8, Segoe UI
Gui, Add, Checkbox, x10 y210 w75 h20 vChkMythical gSelectPetType, Mythical
Gui, Add, Checkbox, x90 y210 w70 h20 vChkEternal gSelectPetType, Eternal
Gui, Add, Checkbox, x180 y210 w70 h20 vChkSecret gSelectPetType, Secret
Gui, Add, Checkbox, x260 y210 w70 h20 vChkDivine gSelectPetType, Divine

Gui, Font, s7, Segoe UI
Gui, Add, Text, x0 y235 w460 Center, N0NG RCU Macro made by Cinnamowopal

Gui, Show, w460 h250, Rebirth Champions: Ultimate - Pet Merging Macro v3.2

while (!SelectorSubmitted)
    Sleep, 50
return

SelectPetType:
    ; Only one at a time: Uncheck others when checking one
    CtrlList := ["ChkMythical", "ChkEternal", "ChkSecret", "ChkDivine"]
    For _, ctrl in CtrlList
    {
        if (A_GuiControl != ctrl)
            GuiControl,, %ctrl%, 0
    }
    ; Set global PetTypeFilter according to which box is checked
    PetTypeFilter := ""
    GuiControlGet, myth,, ChkMythical
    GuiControlGet, ete,, ChkEternal
    GuiControlGet, sec,, ChkSecret
    GuiControlGet, div,, ChkDivine
    if (myth)
        PetTypeFilter := "Mythical"
    else if (ete)
        PetTypeFilter := "Eternal"
    else if (sec)
        PetTypeFilter := "Secret"
    else if (div)
        PetTypeFilter := "Divine"
return

; ----- Button Handlers ----- (unchanged)
SelectCraftAll:
CraftAllMode := true
MergeAllRequested := true
SelectorSubmitted := true
Gui, ModeSelect:Destroy
Gosub, ActivateRoblox
if !EnsureRemoteOpen()
    return
MergeAllPetTypes()
return

SelectGoldenAll:
CraftAllMode := true
CraftMode := "Golden"
SelectorSubmitted := true
Gui, ModeSelect:Destroy
return

SelectToxicAll:
CraftAllMode := true
CraftMode := "Toxic"
SelectorSubmitted := true
Gui, ModeSelect:Destroy
return

SelectGalaxyAll:
CraftAllMode := true
CraftMode := "Galaxy"
SelectorSubmitted := true
Gui, ModeSelect:Destroy
return

SelectMergeAll:
CraftAllMode := false
CraftMode := "" ; prevent regular mode
MergeAllRequested := true
SelectorSubmitted := true
Gui, ModeSelect:Destroy
Gosub, ActivateRoblox
if !EnsureRemoteOpen()
    return

MergeAllPetTypes()
return

SelectGolden:
CraftAllMode := false
CraftMode := "Golden"
SelectorSubmitted := true
Gui, ModeSelect:Destroy
return

SelectToxic:
CraftAllMode := false
CraftMode := "Toxic"
SelectorSubmitted := true
Gui, ModeSelect:Destroy
return

SelectGalaxy:
CraftAllMode := false
CraftMode := "Galaxy"
SelectorSubmitted := true
Gui, ModeSelect:Destroy
return

ModeSelectGuiClose:
CraftMode := ""
SelectorSubmitted := true
Gui, ModeSelect:Destroy
return

; ---------------------------
; Function: Apply search filter if a pet type is chosen
; ---------------------------
ApplySearchFilterIfNeeded()
{
    global PetTypeFilter
    if (PetTypeFilter = "")
        return

    ; Focus search bar (Client 271,434)
    MouseMove, 271, 431, 0
    Sleep, 100
    Click, 271, 434, 1
    Sleep, 100
    ; Clear search field first (simulate Ctrl+A, Del)
    SendInput ^a{Del}
    Sleep, 50
    ; Type in filter
    SendInput %PetTypeFilter%
    Sleep, 280
}

; ---------------------------
; One-time setup after selecting mode
; ---------------------------
PrepareMode:
Loop, 3
{
    ForceRemoteTop()
    Sleep, 100

    if (CraftMode = "Golden")
    {
        GoldenPets()
        Sleep, 400
        if IsGoldenOpen()
        {
            ApplySearchFilterIfNeeded()
            return
        }
    }
    else if (CraftMode = "Toxic")
    {
        ToxicPets()
        Sleep, 400
        if IsToxicOpen()
        {
            ApplySearchFilterIfNeeded()
            return
        }
    }
    else if (CraftMode = "Galaxy")
    {
        GalaxyPets()
        Sleep, 400
        if IsGalaxyOpen()
        {
            ApplySearchFilterIfNeeded()
            return
        }
    }

    CloseOpenPanel()
    Sleep, 450

    if !EnsureRemoteOpen()
        return

    Sleep, 300
}
return

; ---------------------------
; Helper: unified Craft-All action (used by both branches so they behave identically)
; ---------------------------
DoCraftAllAction()
{
    global STOP, SwitchingMode

    MouseMove, 536, 395, 0
    Sleep, 20
    if (STOP || SwitchingMode)
        return false
    if !ClickWithChecks(536, 397, 2)
        return false

    Sleep, 100

    PixelSearch, px, py, 478, 400, 478, 400, 0x105F76, 5, Fast RGB
    if (ErrorLevel = 0)
    {
        MouseMove, 531, 350, 0
        Sleep, 20
        if (STOP || SwitchingMode)
            return false
        if !ClickWithChecks(531, 352, 2)
            return false
        Sleep, 100
    }
    return true
}

; ---------------------------
; Main craft loop
; ---------------------------
MainLoop:
Loop
{
    if (STOP || SwitchingMode)
        break

    while (PAUSED && !STOP && !SwitchingMode)
        Sleep, 100

    if (STOP || SwitchingMode)
        break

    ; --- Check for disabled before any clicks ---
    if (IsCraft1Disabled())
    {
        CloseOpenPanel()
        RemoteComputer()

        ; If CraftAllMode (craft-all UI) -> stop/exit loop as before
        if (CraftAllMode)
        {
            break
        }

        ; If we're in a MergeAllRequested cycle (user selected "All Types" in the 1-by-1 side),
        ; treat this as "this variant finished" and break so MergeAllPetTypes can continue to next variant.
        else if (MergeAllRequested)
        {
            if (DEBUG)
                FileAppend, % A_Now " - Detected finished variant while MergeAllRequested, breaking to continue cycle.`n", %DEBUG_LOG%
            break
        }

        ; Otherwise, for normal single-mode runs, pause and show tooltip (existing behavior)
        else
        {
            ToolTip, All crafts complete! Paused. Press F2 to resume.
            SetTimer, RemoveToolTip, -2500

            PAUSED := true

            ; Wait until user resumes or the script is stopped/switching mode
            while (PAUSED && !STOP && !SwitchingMode)
                Sleep, 200

            if (STOP || SwitchingMode)
                break

            ; Continue to next iteration after resume
            continue
        }
    }

    ; Click Top Left Pet
    MouseMove, 218, 195, 0
    Sleep, 20
    if (STOP || SwitchingMode)
        break
    if !ClickWithChecks(218, 197, 1)
        break
    Sleep, 70
    if (STOP || SwitchingMode)
        break

    ; --- Craft All Logic (left: uses Craft All, right: only Craft 1 in all cases) ---
    if (CraftAllMode)
    {
        if (!DoCraftAllAction())
            break
        goto ClickOkAndContinue
    }
    else
    {
        ; Always perform a single-craft (Craft 1) click for each pet
        if (robloxExe != "")
        {
            WinActivate, ahk_exe %robloxExe%
            WinWaitActive, ahk_exe %robloxExe%,, 1
        }

        MouseMove, 531, 350, 0
        Sleep, 20
        if (STOP || SwitchingMode)
            break

        if !ClickWithChecks(531, 352, 2)
            break

        Sleep, 100
    }
    if (STOP || SwitchingMode)
        break

ClickOkAndContinue:
    ; Click Okay/Clear Message (raw/direct as upstream)
    MouseMove, 400, 365, 0
    Sleep, 30
    if (STOP || SwitchingMode)
        break
    Click, 400, 371, 1
    Sleep, 500
    if (STOP || SwitchingMode)
        break

    ; ---------------------------
    ; Pixel-check recovery: verify the soft-white UI element is present.
    ; Client coords provided: 435, 173. Color: 0xFDFDFD
    ; If it's NOT found, attempt recovery / re-open sequence depending on mode.
    ; ---------------------------
    PixelGetColor, pfColor, 435, 173, RGB
    if (DEBUG)
        FileAppend, % A_Now " - post-OK pixel: 0x" Format("{:06X}", pfColor) "`n", %DEBUG_LOG%

    ; Use ColorNear to allow small color variance (tolerance = 8)
    if (!ColorNear(pfColor, 0xFDFDFD, 8))
    {
        if (DEBUG)
            FileAppend, % A_Now " - Soft-white UI not detected at client(435,173). Running recovery sequence.`n", %DEBUG_LOG%

        ; Try a conservative recovery procedure:
        ; 1) Close any open panel (safe)
        ; 2) Ensure remote / panel is open
        ; 3) Re-run PrepareMode to put UI back into expected state for current CraftMode
        CloseOpenPanel()
        Sleep, 300

        if !EnsureRemoteOpen()
        {
            ; If remote still not open, attempt RemoteComputer and wait briefly
            RemoteComputer()
            Sleep, 600
        }

        ; Re-prepare the mode (this repeats the steps used when selecting a mode)
        Gosub, PrepareMode

        ; Small pause to allow UI stabilize
        Sleep, 400
    }

    ; Move away from the pet list to reduce accidental clicks during lag
    MouseMove, 462, 353, 0
    Sleep, 200
}
return

; ---------------------------
; Merge-All mode with pet cycling
; ---------------------------
MergeAllPetTypes()
{
    STOP := false
    PAUSED := false
    MergeAllRequested := true

    ; Gold
    CraftMode := "Golden"
    Gosub, PrepareMode
    Gosub, MainLoop

    ; Toxic
    CraftMode := "Toxic"
    Gosub, PrepareMode
    Gosub, MainLoop

    ; Galaxy
    CraftMode := "Galaxy"
    Gosub, PrepareMode
    Gosub, MainLoop

    ToolTip, All merges complete!
    Sleep, 2000
    ToolTip
    MergeAllRequested := false
    Pause
}

; ---------------------------
; Functions
; ---------------------------
ColorNear(c1, c2, tol := 20)
{
    r1 := (c1 >> 16) & 0xFF
    g1 := (c1 >> 8) & 0xFF
    b1 := c1 & 0xFF

    r2 := (c2 >> 16) & 0xFF
    g2 := (c2 >> 8) & 0xFF
    b2 := c2 & 0xFF

    return (Abs(r1-r2) <= tol && Abs(g1-g2) <= tol && Abs(b1-b2) <= tol)
}

IsCraft1Disabled()
{
    ; Scan a region from (478, 346) to (585, 374) for the disabled color with tolerance
    PixelSearch, px, py, 478, 346, 585, 374, 0x3B7814, 40, Fast RGB
    return (ErrorLevel = 0)
}

IsRemoteOpen()
{
    PixelSearch, px, py, 540, 165, 570, 195, 0xF42549, 50, Fast RGB
    if (ErrorLevel = 0)
        return true

    PixelSearch, px, py, 540, 165, 570, 195, 0xFD3758, 50, Fast RGB
    if (ErrorLevel = 0)
        return true

    PixelSearch, px, py, 540, 165, 570, 195, 0xF11F44, 50, Fast RGB
    return (ErrorLevel = 0)
}

IsGoldenOpen()
{
    PixelGetColor, c, 555, 414, RGB
    return ColorNear(c, 0xFF9C3A, 40)
}

IsToxicOpen()
{
    PixelGetColor, c, 589, 407, RGB
    return ColorNear(c, 0x4CFC43, 30)
}

IsGalaxyOpen()
{
    PixelGetColor, c, 576, 420, RGB
    return ColorNear(c, 0x551AFC, 40)
}

RemoteComputer()
{
    MouseMove, 78, 369, 0
    Sleep, 120
    Click, 78, 371, 1
    Sleep, 1000
}

EnsureRemoteOpen()
{
    if IsRemoteOpen()
        return true

    RemoteComputer()
    Sleep, 500

    if IsRemoteOpen()
        return true

    Sleep, 500
    return IsRemoteOpen()
}

CloseOpenPanel()
{
    WinActivate, ahk_exe %robloxExe%
    WinWaitActive, ahk_exe %robloxExe%,, 2
    Sleep, 400

    MouseMove, 606, 161, 0
    Sleep, 120
    Click, 606, 163, 1
    Sleep, 450
}

ForceRemoteTop()
{
    MouseMove, 377, 293, 0
    Sleep, 250
    MouseMove, 377, 295, 0
    Sleep, 250

    Loop, 20
    {
        SendEvent {WheelUp}
        Sleep, 25
    }
    Sleep, 250
}

GoldenPets()
{
    MouseMove, 505, 315, 0
    Sleep, 150
    Click, 505, 317, 1
    Sleep, 300
}

ToxicPets()
{
    MouseMove, 559, 208, 0
    Sleep, 200
    MouseMove, 559, 210, 0
    Sleep, 200

    Click, Down
    Sleep, 350
    MouseMove, 503, 250, 12
    Sleep, 350
    Click, Up
    Sleep, 350

    MouseMove, 506, 233, 0
    Sleep, 200
    Click, 506, 235, 1
    Sleep, 300
}

GalaxyPets()
{
    MouseMove, 559, 208, 0
    Sleep, 100
    MouseMove, 559, 210, 0
    Sleep, 350

    Click, Down
    Sleep, 500
    MouseMove, 561, 306, 12
    Sleep, 350
    Click, Up
    Sleep, 350

    MouseMove, 506, 332, 0
    Sleep, 300
    Click, 506, 334, 1
    Sleep, 300
}

; ---------------------------
; Click helper that allows interruption and respects PAUSED/STOP/SwitchingMode
; - Performs 'count' individual clicks with short sleeps and checks between them.
; - Returns false if interrupted (STOP or SwitchingMode), true otherwise.
; ---------------------------
ClickWithChecks(x, y, count := 1)
{
    global STOP, PAUSED, SwitchingMode, robloxExe, DEBUG, DEBUG_LOG

    Loop, %count%
    {
        ; immediate cancellation/resume checks
        if (STOP || SwitchingMode)
        {
            if (DEBUG)
                FileAppend, % A_Now " - ClickWithChecks cancelled before click (STOP/SwitchingMode).`n", %DEBUG_LOG%
            return false
        }

        ; respect pause (this loop allows F2 to interrupt because Thread, Interrupt is enabled)
        while (PAUSED && !STOP && !SwitchingMode)
            Sleep, 50

        ; ensure the Roblox window is active (this helps when focus is lost)
        if (robloxExe != "")
        {
            WinActivate, ahk_exe %robloxExe%
            ; Wait a short time for activation; don't block forever
            WinWaitActive, ahk_exe %robloxExe%,, 1
        }

        ; log pre-click state
        MouseGetPos, mx, my, winUnder, controlUnder
        if (DEBUG)
        {
            msg := A_Now " - Click attempt: (" x "," y ")  mouse:" mx "," my "  win:" winUnder "  pause:" PAUSED
            FileAppend, % msg "`n", %DEBUG_LOG%
        }

        ; perform the click
        Click, %x%, %y%, 1

        ; give UI extra time and make the click interruptible
        Sleep, 120

        ; log after-click (mouse pos & time)
        if (DEBUG)
        {
            MouseGetPos, mx2, my2
            FileAppend, % A_Now " - Click completed. mouse now: " mx2 "," my2 "`n", %DEBUG_LOG%
        }
    }
    return true
}

RemoveToolTip:
ToolTip
return
