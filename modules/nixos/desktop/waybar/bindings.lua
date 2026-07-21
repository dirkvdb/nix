-- Hyprland keybindings specific to the waybar-based shell (walker, swayosd).
-- Only sourced when local.desktop.waybar.enable is true; the
-- Noctalia alternative provides its own launcher/OSD and keybinds.
local mod = "SUPER"
local osdclient = 'swayosd-client --monitor "$(hyprctl monitors -j | jq -r \'.[] | select(.focused == true).name\')"'

---- LAUNCHER / CLIPBOARD ----
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd("walker -N"), { description = "Launch apps" })
hl.bind(mod .. " + V", hl.dsp.exec_cmd("walker --provider clipboard --theme clipboard"), { description = "Clipboard" })

---- POWER MENU ----
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("nixcfg-menu system"), { locked = true, description = "Power menu" })
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("nixcfg-menu system"), { description = "Power menu" })

---- MEDIA / BRIGHTNESS (swayosd) ----
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(osdclient .. " --output-volume raise"), { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(osdclient .. " --output-volume lower"), { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(osdclient .. " --output-volume mute-toggle"), { locked = true, repeating = true, description = "Mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(osdclient .. " --input-volume mute-toggle"), { locked = true, repeating = true, description = "Mute microphone" })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(osdclient .. " --brightness +5"), { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osdclient .. " --brightness -5"), { locked = true, repeating = true, description = "Brightness down" })
-- Precise 1% adjustments with Alt modifier
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd(osdclient .. " --output-volume +1"), { locked = true, repeating = true, description = "Volume up precise" })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd(osdclient .. " --output-volume -1"), { locked = true, repeating = true, description = "Volume down precise" })
hl.bind("ALT + XF86MonBrightnessUp", hl.dsp.exec_cmd(osdclient .. " --brightness +1"), { locked = true, repeating = true, description = "Brightness up precise" })
hl.bind("ALT + XF86MonBrightnessDown", hl.dsp.exec_cmd(osdclient .. " --brightness -1"), { locked = true, repeating = true, description = "Brightness down precise" })
