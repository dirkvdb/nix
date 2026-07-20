-- Hyprland keybindings specific to the Noctalia shell.
-- Only sourced when local.desktop.noctalia.enable is true; the waybar
-- alternative provides its own launcher/OSD and keybinds instead.
local mod = "SUPER"

---- POWER MENU ----
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), { locked = true, description = "Power menu" })
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), { description = "Power menu" })

---- LAUNCHER / CLIPBOARD ----
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { description = "App launcher" })
hl.bind(mod .. " + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"), { description = "Clipboard" })

---- BRIGHTNESS (Noctalia OSD) ----
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("noctalia msg brightness-up"), { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true, description = "Brightness down" })

---- VOLUME / MIC (Noctalia OSD) ----
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"), { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"), { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"), { locked = true, repeating = true, description = "Mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("noctalia msg mic-mute"), { locked = true, repeating = true, description = "Mute microphone" })
