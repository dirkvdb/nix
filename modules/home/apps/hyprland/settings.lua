-- Static Hyprland settings (no NixOS dependencies).
-- Theme-dependent values (border colors, startup commands, monitors)
-- are set separately in the generated hyprland.lua.

--------------------
---- ANIMATIONS ----
--------------------

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "default", style = "fade" })


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    animations = { enabled = true },
    xwayland = { force_zero_scaling = true },
    ecosystem = { no_update_news = true },

    -- Border colors (general.col, group.col) are set via Nix (theme-dependent)
    general = {
        gaps_in          = 3,
        gaps_out         = 6,
        border_size      = 2,
        layout           = "dwindle",
        resize_on_border = false,
        allow_tearing    = false,
    },

    decoration = {
        rounding = 8,
        shadow = {
            enabled      = true,
            range        = 2,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size    = 3,
            passes  = 3,
        },
    },

    dwindle = {
        preserve_split = true,
        force_split    = 2,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        focus_on_activate        = true,
        -- Application not responding (ANR) detection settings
        anr_missed_pings         = 3,
    },

    cursor = {
        no_hardware_cursors = false,
        enable_hyprcursor   = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout          = "us",
        kb_options         = "caps:escape",
        repeat_rate        = 35,
        repeat_delay       = 300,
        numlock_by_default = true,
        sensitivity        = 0.2,
        touchpad           = {
            natural_scroll       = true,
            clickfinger_behavior = true,
            tap_to_click         = true,
            drag_lock            = false,
            tap_and_drag         = true,
        },
    },
})


-----------------
---- DEVICES ----
-----------------

hl.device({
    name                 = "apple-mtp-multi-touch",
    tap_to_click         = false,
    clickfinger_behavior = true,
    disable_while_typing = true,
    scroll_factor        = 0.3,
})

hl.device({
    name       = "apple-mtp-keyboard",
    kb_options = "",
})


------------------
---- GESTURES ----
------------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen", scale = 1.5 })
hl.gesture({ fingers = 3, direction = "down", action = "close" })


---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({ match = { namespace = "walker" }, no_anim = true })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })


-------------------------
---- WORKSPACE RULES ----
-------------------------
hl.workspace_rule({ workspace = "1", persistent = true })
hl.workspace_rule({ workspace = "2", persistent = true })
hl.workspace_rule({ workspace = "3", no_rounding = true, decorate = false, gaps_in = 0, gaps_out = 0, persistent = true })
hl.workspace_rule({ workspace = "3", persistent = true })
hl.workspace_rule({ workspace = "4", persistent = true })
hl.workspace_rule({ workspace = "5", layout = "scrolling", persistent = true })
hl.workspace_rule({ workspace = "6", persistent = true })
hl.workspace_rule({ workspace = "7", persistent = true })
hl.workspace_rule({ workspace = "8", persistent = true })
hl.workspace_rule({ workspace = "9", persistent = true })


-----------------------
---- WINDOW RULES ----
-----------------------

-- Disable window opacity
hl.window_rule({ match = { class = ".*" }, opacity = "1 1" })

-- Floating windows
hl.window_rule({ match = { tag = "floating-window" }, float = true })
hl.window_rule({ match = { tag = "floating-window" }, center = true })
hl.window_rule({ match = { tag = "floating-window" }, size = "1024 768" })

-- Float LocalSend and fzf file picker
hl.window_rule({ match = { class = "(Share|localsend)" }, float = true })
hl.window_rule({ match = { class = "(Share|localsend)" }, center = true })

-- Define terminal tag
hl.window_rule({ match = { class = "(Alacritty|kitty|com.mitchellh.ghostty)" }, tag = "+terminal" })

-- Float specific apps
hl.window_rule({ match = { class = "org.gnome.Calculato" }, float = true })
hl.window_rule({ match = { class = "com.github.finefindus.eyedropper" }, float = true })

-- Tag floating windows
hl.window_rule({
    match = { class = "(blueberry.py|io.github.kaii_lb.Overskride|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float|org.keepassxc.KeePassXC)" },
    tag = "+floating-window",
})
hl.window_rule({
    match = {
        class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)",
        title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files)",
    },
    tag = "+floating-window",
})

-- Browser types
hl.window_rule({
    match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable|helium)" },
    tag =
    "+chromium-based-browser"
})
hl.window_rule({ match = { class = "([fF]irefox|zen|librewolf)" }, tag = "+firefox-based-browser" })

-- Force chromium-based browsers into a tile to deal with --app bug
hl.window_rule({ match = { tag = "chromium-based-browser" }, tile = true })

-- Picture-in-picture overlays
hl.window_rule({ match = { title = "(Picture.?in.?[Pp]icture)" }, tag = "+pip" })
hl.window_rule({ match = { tag = "pip" }, float = true })
hl.window_rule({ match = { tag = "pip" }, pin = true })
hl.window_rule({ match = { tag = "pip" }, size = "600 338" })
hl.window_rule({ match = { tag = "pip" }, keep_aspect_ratio = true })
hl.window_rule({ match = { tag = "pip" }, border_size = 0 })
hl.window_rule({ match = { tag = "pip" }, opacity = "1 1" })
hl.window_rule({ match = { tag = "pip" }, move = "100%-w-40 4%" })

-- No password manager screenshare
hl.window_rule({ match = { class = "^(Bitwarden|org.keepassxc.KeePassXC)$" }, no_screen_share = true })

-- Workspace assignments
hl.window_rule({ match = { class = "(vivaldi-stable)" }, workspace = "2" })
hl.window_rule({ match = { class = "(firefox|Firefox|librewolf)" }, workspace = "2" })
hl.window_rule({ match = { class = "(zen|zen-beta)" }, workspace = "2" })
hl.window_rule({ match = { class = "(dev.zed.Zed|dev.zed.Zed-Dev)" }, workspace = "3" })
hl.window_rule({ match = { class = "(org.gnome.Nautilus|thunar)" }, workspace = "5" })
hl.window_rule({ match = { class = "(Spotify|chrome-open\\.spotify\\.com__.*)" }, workspace = "9" })
hl.window_rule({ match = { class = "(sublime_merge)" }, workspace = "6" })
hl.window_rule({ match = { class = "(slack)" }, workspace = "7" })
hl.window_rule({ match = { class = "(outlook-for-linux|chrome-outlook\\.office365\\.com__.*)" }, workspace = "8 silent" })
hl.window_rule({ match = { class = "(teams-for-linux)" }, workspace = "8 silent" })

-- Fullscreen border color indicator
hl.window_rule({ match = { fullscreen = true }, border_color = "rgb(FFCC66) rgb(DEC186)" })

-- Float specific apps
hl.window_rule({ match = { class = "^(nordvpn-gui)$" }, float = true })

-- Fladder media player fullscreen
hl.window_rule({ match = { class = "^(Fladder)$" }, fullscreen = true })
hl.window_rule({ match = { class = "^(Fladder)$" }, fullscreen_state = "2 2" })
hl.window_rule({ match = { class = "^(Fladder)$" }, border_size = 0 })
