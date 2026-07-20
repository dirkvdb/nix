-- Hyprland keybindings specific to the Noctalia shell.
-- Only sourced when local.desktop.noctalia.enable is true; the waybar
-- alternative provides its own launcher/OSD and keybinds instead.
local mod = "SUPER"

---- POWER MENU ----
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), { locked = true, description = "Power menu" })
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), { description = "Power menu" })
