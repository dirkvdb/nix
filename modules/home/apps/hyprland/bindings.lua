-- Hyprland keybindings (no NixOS dependencies).
-- Conditional binds (music, VPN, officework) are added via Nix.
local mod         = "SUPER"
local terminal    = "ghostty"
local browser     = "zen-beta"
local applauncher = "walker -N"
local osdclient   = 'swayosd-client --monitor "$(hyprctl monitors -j | jq -r \'.[] | select(.focused == true).name\')"'

--- Focus an existing window by class, or launch the command if none found.
--- Global so Nix-injected bindings (appended after require("bindings")) can use it.
function launch_or_focus(class_pattern, launch_cmd)
    launch_cmd = launch_cmd or class_pattern
    return function()
        for _, w in ipairs(hl.get_windows()) do
            if w.class:find(class_pattern, 1, true) then
                hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
                return
            end
        end
        hl.exec_cmd(launch_cmd)
    end
end

---- WINDOW MOVE / LAYOUT ----
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mod .. " + backslash", hl.dsp.layout("togglesplit"))
---- MOUSE BINDS ----
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + ALT + mouse:272", hl.dsp.window.resize(), { mouse = true })
---- SYSTEM / UTILITY ----
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("nixcfg-menu system"), { locked = true, description = "Power menu" })
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("nixcfg-menu system"), { description = "Power menu" })
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(applauncher), { description = "Launch apps" })
hl.bind(mod .. " + ALT + SPACE", hl.dsp.exec_cmd("nixcfg-menu"), { description = "Menu" })
hl.bind(mod .. " + X", hl.dsp.workspace.toggle_special(), { description = "Special workspace" })
hl.bind(mod .. " + CTRL + S", hl.dsp.exec_cmd("nixcfg-menu share"), { description = "Share" })
hl.bind(mod .. " + CTRL + I", hl.dsp.exec_cmd("nixcfg-toggle-idle"), { description = "Toggle locking on idle" })
hl.bind(mod .. " + CTRL + N", hl.dsp.exec_cmd("nixcfg-toggle-nightlight"), { description = "Toggle nightlight" })
---- APP LAUNCHERS -------
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal .. ' --working-directory="$(nixcfg-cmd-terminal-cwd)"'), { description = "Terminal" })
hl.bind(mod .. " + S", launch_or_focus(browser), { description = "Browser" })
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(browser), { description = "Browser (new instance)" })
hl.bind(mod .. " + D", hl.dsp.exec_cmd("zeditor"), { description = "Dev editor" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd("nautilus --new-window"), { description = "File manager" })
hl.bind(mod .. " + SHIFT + G", hl.dsp.exec_cmd("sublime_merge"), { description = "Sublime merge" })
hl.bind(mod .. " + T", hl.dsp.exec_cmd(terminal .. " -e btop"), { description = "Activity" })
hl.bind(mod .. " + V", hl.dsp.exec_cmd("walker --provider clipboard --theme clipboard"), { description = "Clipboard" })
hl.bind(mod .. " + K", hl.dsp.exec_cmd("nixcfg-menu-keybindings"), { description = "Show key bindings" })
---- WEB APPS ----
hl.bind(mod .. " + SHIFT + A", launch_or_focus("ChatGPT", 'nixcfg-launch-webapp "https://chatgpt.com"'), { description = "ChatGPT" })
hl.bind(mod .. " + SHIFT + Y", launch_or_focus("Youtube", 'nixcfg-launch-webapp "https://youtube.com/"'), { description = "Youtube" })
hl.bind(mod .. " + SHIFT + W", launch_or_focus("Whatsapp", 'nixcfg-launch-webapp "https://web.whatsapp.com/"'), { description = "Whatsapp" })
hl.bind(mod .. " + SHIFT + E", launch_or_focus("GMail", 'nixcfg-launch-webapp "https://mail.google.com"'), { description = "Email" })
---- WINDOW MANAGEMENT ---
hl.bind(mod .. " + W", hl.dsp.window.close(), { description = "Close active window" })
hl.bind(mod .. " + DELETE", hl.dsp.exec_cmd("hyprctl kill"), { description = "Kill window (click to kill)" })
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize App Window" })
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind(mod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Full width" })
---- OFFICE / SERVICES -------
hl.bind(mod .. " + SHIFT + O", hl.dsp.exec_cmd("systemctl --user start work.target"), { description = "Office applications" })
hl.bind(mod .. " + SHIFT + ALT + O", hl.dsp.exec_cmd("systemctl --user stop work.target"), { description = "Close office applications" })
---- WINDOW RESIZING -----
hl.bind(mod .. " + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { description = "Expand window left" })
hl.bind(mod .. " + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { description = "Shrink window left" })
hl.bind(mod .. " + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { description = "Shrink window up" })
hl.bind(mod .. " + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { description = "Expand window down" })
---- FOCUS --------
hl.bind(mod .. " + LEFT", hl.dsp.focus({ direction = "l" }), { description = "Move focus left" })
hl.bind(mod .. " + RIGHT", hl.dsp.focus({ direction = "r" }), { description = "Move focus right" })
hl.bind(mod .. " + UP", hl.dsp.focus({ direction = "u" }), { description = "Move focus up" })
hl.bind(mod .. " + DOWN", hl.dsp.focus({ direction = "d" }), { description = "Move focus down" })
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }), { description = "Move focus left" })
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }), { description = "Move focus right" })
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }), { description = "Move focus up" })
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }), { description = "Move focus down" })

hl.bind("CTRL + ALT + LEFT", hl.dsp.focus({ workspace = "-1" }), { description = "Navigate workspace left" })
hl.bind("CTRL + ALT + RIGHT", hl.dsp.focus({ workspace = "+1" }), { description = "Navigate workspace right" })

---- WORKSPACES -------
for i = 1, 10 do
    local key = "code:" .. (i + 9) -- code:10 = 1, code:11 = 2, ..., code:19 = 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Move window to workspace " .. i })
end

---- GROUPS -------
hl.bind(mod .. " + G", hl.dsp.group.toggle(), { description = "Toggle window grouping" })
hl.bind(mod .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Move active window out of group" })
hl.bind(mod .. " + ALT + LEFT", hl.dsp.window.move({ into_group = "l" }), { description = "Move window to group on left" })
hl.bind(mod .. " + ALT + RIGHT", hl.dsp.window.move({ into_group = "r" }), { description = "Move window to group on right" })
hl.bind(mod .. " + ALT + UP", hl.dsp.window.move({ into_group = "u" }), { description = "Move window to group on top" })
hl.bind(mod .. " + ALT + DOWN", hl.dsp.window.move({ into_group = "d" }), { description = "Move window to group on bottom" })
hl.bind(mod .. " + ALT + TAB", hl.dsp.group.next(), { description = "Next window in group" })
hl.bind(mod .. " + ALT + SHIFT + TAB", hl.dsp.group.prev(), { description = "Previous window in group" })
---- SCREENSHOTS --------
hl.bind(mod .. " + ALT + 4", hl.dsp.exec_cmd("nixcfg-cmd-screenshot"), { description = "Screenshot of region" })
hl.bind(mod .. " + ALT + 3", hl.dsp.exec_cmd("nixcfg-cmd-screenshot window"), { description = "Screenshot of window" })
hl.bind(mod .. " + ALT + 2", hl.dsp.exec_cmd("nixcfg-cmd-screenshot output"), { description = "Screenshot of display" })
hl.bind(mod .. " + ALT + 5", hl.dsp.exec_cmd("nixcfg-cmd-screenrecord"), { description = "Record screen region" })
hl.bind(mod .. " + ALT + 6", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"), { description = "Color picker" })
---- MEDIA / BRIGHTNESS ------
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
---- WORKSPACE OVERVIEW ----
hl.bind(mod .. " + TAB", hl.dsp.exec_cmd("pkill -SIGUSR1 -x hyprexpose"), { description = "Workspace overview" })
