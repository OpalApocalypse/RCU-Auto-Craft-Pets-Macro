#NoEnv
#SingleInstance Force
#MaxThreadsPerHotkey 2
Thread, Interrupt, 0

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
; F2 - Pause / Unpause
; ---------------------------
F2::
if (SwitchingMode)
    return

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
; GUI selector WITH Merge All Option
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
; Left column buttons, each now has g-label and sets CraftMode to actual variant
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
; Right column buttons, unchanged assignments
Gui, Add, Button, x295 y98 w100 h27 gSelectMergeAll, All Types
Gui, Add, Button, x244 y132 w62 h28 gSelectGolden, Golden
Gui, Add, Button, x314 y132 w62 h28 gSelectToxic, Toxic
Gui, Add, Button, x384 y132 w62 h28 gSelectGalaxy, Galaxy

; --- Vertical Center Line (cuts off below buttons) ---
Gui, Add, Progress, x229 y10 w3 h162 -Smooth cBlack, 100

; --- Horizontal Line Across the Bottom ---
Gui, Add, Progress, x0 y180 w460 h3 -Smooth cBlack, 100

; --- Credit Line (raised, very small and centered) ---
Gui, Font, s7, Segoe UI
Gui, Add, Text, x0 y185 w460 Center, N0NG RCU Macro made by Cinnamowopal

Gui, Show, w460 h200, Rebirth Champions: Ultimate - Pet Merging Macro v3.1

while (!SelectorSubmitted)
    Sleep, 50
return

; ----- Button Handlers -----
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
            return
    }
    else if (CraftMode = "Toxic")
    {
        ToxicPets()
        Sleep, 400
        if IsToxicOpen()
            return
    }
    else if (CraftMode = "Galaxy")
    {
        GalaxyPets()
        Sleep, 400
        if IsGalaxyOpen()
            return
    }

    CloseOpenPanel()
    Sleep, 450

    if !EnsureRemoteOpen()
        return

    Sleep, 300
}
return

; ---------------------------
; Main craft loop, with CraftAllMode support and pixel check for Craft All exception and end-of-pets detection for both modes
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
        break
    }

    ; Click Top Left Pet
    MouseMove, 218, 195, 0
    if (STOP || SwitchingMode)
        break
    Click, 218, 197, 1
    Sleep, 250
    if (STOP || SwitchingMode)
        break

    ; Click Craft or Craft All with pixel check exception for Craft All
    if (CraftAllMode)
    {
        MouseMove, 536, 395, 0
        if (STOP || SwitchingMode)
            break
        Click, 536, 397, 2
        Sleep, 250

        ; Pixel check: If Craft All is unavailable, fallback to Craft 1
        PixelSearch, px, py, 478, 400, 478, 400, 0x105F76, 5, Fast RGB
        if (ErrorLevel = 0)
        {
            MouseMove, 531, 350, 0
            if (STOP || SwitchingMode)
                break
            Click, 531, 352, 2
            Sleep, 250
        }
    }
    else
    {
        MouseMove, 531, 350, 0
        if (STOP || SwitchingMode)
            break
        Click, 531, 352, 2
        Sleep, 250
    }
    if (STOP || SwitchingMode)
        break

    ; Click Okay/Clear Message
    MouseMove, 400, 365, 0
    if (STOP || SwitchingMode)
        break
    Click, 400, 371, 1
    Sleep, 250
    if (STOP || SwitchingMode)
        break

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

RemoveToolTip:
ToolTip
return