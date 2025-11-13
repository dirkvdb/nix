{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  isLinux = pkgs.stdenv.isLinux;
  isX86 = pkgs.stdenv.isx86_64;
in
{
  home-manager.users.${user.name} = lib.mkIf isLinux {
    wayland.windowManager.hyprland.settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$browser" = "zen-beta";
      "$applauncher" = "nc -U /run/user/1000/walker/walker.sock";

      bind = [
        # scrolling layout controls
        # "$mod SHIFT, L, layoutmsg, movewindowto r"
        # "$mod SHIFT, H, layoutmsg, movewindowto l"
        # "$mod SHIFT, I, layoutmsg, promote"
        # "$mod SHIFT ALT, L, layoutmsg, move +col"
        # "$mod SHIFT ALT, H, layoutmsg, move -col"

        # tiling layout controls
        # Swap active window with the one next to it with SUPER + SHIFT + arrow keys (VIM style)
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"
        "$mod, backslash, togglesplit"
      ];

      bindm = [
        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];

      bindld = [
        ", XF86PowerOff, Power menu, exec, nixcfg-menu system"
      ];

      bindd = [
        "$mod, SPACE, Launch apps, exec, $applauncher"
      ]
      # Export workspace overview with SUPER + ~ (only on x86_64)
      ++ lib.optionals isX86 [
        "$mod, GRAVE, Workspace overview, hyprexpo:expo, toggle"
      ]
      ++ [
        "$mod ALT, SPACE, Menu, exec, nixcfg-menu"

        "$mod, ESCAPE, Power menu, exec, nixcfg-menu system"
        "$mod, RETURN, Terminal, exec, $terminal --working-directory=\"$(nixcfg-cmd-terminal-cwd)\""
        "$mod, B, Browser, exec, nixcfg-launch-or-focus $browser"
        "$mod SHIFT, B, Browser (new instance), exec, $browser"
        "$mod, D, Dev editor, exec, zeditor"
        "$mod, E, File manager, exec, nautilus --new-window"
        "$mod SHIFT, A, ChatGPT, exec, nixcfg-launch-or-focus-webapp ChatGPT \"https://chatgpt.com\""
        "$mod SHIFT, M, Music, exec, nixcfg-launch-or-focus spotify"
        "$mod SHIFT, Y, Youtube, exec, nixcfg-launch-or-focus-webapp Youtube \"https://youtube.com/\""
        "$mod SHIFT, W, Whatsapp, exec, nixcfg-launch-or-focus-webapp Whatsapp \"https://web.whatsapp.com/\""
        "$mod SHIFT, E, Email, exec, nixcfg-launch-or-focus-webapp GMail \"https://mail.google.com\""
        "$mod SHIFT, slash, Passwords, exec, bitwarden"
        "$mod, M, Music, exec, nixcfg-launch-or-focus spotify"
        "$mod, W, Close active window, killactive,"
        "$mod, K, Show key bindings, exec, nixcfg-menu-keybindings"
        "$mod, T, Activity, exec, $terminal -e btop"
        "CONTROL SHIFT, V, Clipboard, exec, walker --provider clipboard --theme clipboard"
        "$mod SHIFT, O, Office applications, exec, systemctl --user start work.target"
        "$mod SHIFT ALT, O, Close office applications, exec, systemctl --user stop work.target"

        "$mod CTRL, I, Toggle locking on idle, exec, nixcfg-toggle-idle"
        "$mod CTRL, N, Toggle nightlight, exec, nixcfg-toggle-nightlight"
        "$mod CTRL, S, Share, exec, nixcfg-menu share"

        # Control tiling
        "$mod SHIFT, V, Toggle floating, togglefloating"
        "$mod SHIFT, F, Maximize App Window, fullscreen, 1"
        "$mod ALT, F, Full width, fullscreen, 0"

        "$mod, code:20, Expand window left, resizeactive, -100 0" # - key
        "$mod, code:21, Shrink window left, resizeactive, 100 0" # = key
        "$mod SHIFT, code:20, Shrink window up, resizeactive, 0 -100"
        "$mod SHIFT, code:21, Expand window down, resizeactive, 0 100"

        # Move focus with SUPER + arrow keys
        "$mod, LEFT, Move focus left, movefocus, l"
        "$mod, RIGHT, Move focus right, movefocus, r"
        "$mod, UP, Move focus up, movefocus, u"
        "$mod, DOWN, Move focus down, movefocus, d"
        # Move focus with SUPER + vim arrow keys
        "$mod, H, Move focus left, movefocus, l"
        "$mod, L, Move focus right, movefocus, r"
        "$mod, K, Move focus up, movefocus, u"
        "$mod, J, Move focus down, movefocus, d"

        # Switch workspaces with SUPER + [0-9]
        "$mod, code:10, Switch to workspace 1, workspace, 1"
        "$mod, code:11, Switch to workspace 2, workspace, 2"
        "$mod, code:12, Switch to workspace 3, workspace, 3"
        "$mod, code:13, Switch to workspace 4, workspace, 4"
        "$mod, code:14, Switch to workspace 5, workspace, 5"
        "$mod, code:15, Switch to workspace 6, workspace, 6"
        "$mod, code:16, Switch to workspace 7, workspace, 7"
        "$mod, code:17, Switch to workspace 8, workspace, 8"
        "$mod, code:18, Switch to workspace 9, workspace, 9"
        "$mod, code:19, Switch to workspace 10, workspace, 10"

        # Move active window to a workspace with SUPER + SHIFT + [0-9]
        "$mod SHIFT, code:10, Move window to workspace 1, movetoworkspace, 1"
        "$mod SHIFT, code:11, Move window to workspace 2, movetoworkspace, 2"
        "$mod SHIFT, code:12, Move window to workspace 3, movetoworkspace, 3"
        "$mod SHIFT, code:13, Move window to workspace 4, movetoworkspace, 4"
        "$mod SHIFT, code:14, Move window to workspace 5, movetoworkspace, 5"
        "$mod SHIFT, code:15, Move window to workspace 6, movetoworkspace, 6"
        "$mod SHIFT, code:16, Move window to workspace 7, movetoworkspace, 7"
        "$mod SHIFT, code:17, Move window to workspace 8, movetoworkspace, 8"
        "$mod SHIFT, code:18, Move window to workspace 9, movetoworkspace, 9"
        "$mod SHIFT, code:19, Move window to workspace 10, movetoworkspace, 10"

        # Toggle groups
        "$mod, G, Toggle window grouping, togglegroup"
        "$mod ALT, G, Move active window out of group, moveoutofgroup"

        # Join groups
        "$mod ALT, LEFT, Move window to group on left, moveintogroup, l"
        "$mod ALT, RIGHT, Move window to group on right, moveintogroup, r"
        "$mod ALT, UP, Move window to group on top, moveintogroup, u"
        "$mod ALT, DOWN, Move window to group on bottom, moveintogroup, d"

        # Navigate a single set of grouped windows
        "$mod ALT, TAB, Next window in group, changegroupactive, f"
        "$mod ALT SHIFT, TAB, Previous window in group, changegroupactive, b"

        # Activate window in a group by number
        # "$mod ALT, 1, Switch to group window 1, changegroupactive, 1"
        # "$mod ALT, 2, Switch to group window 2, changegroupactive, 2"
        # "$mod ALT, 3, Switch to group window 3, changegroupactive, 3"
        # "$mod ALT, 4, Switch to group window 4, changegroupactive, 4"
        # "$mod ALT, 5, Switch to group window 5, changegroupactive, 5"

        # Screenshots
        "$mod ALT, 4, Screenshot of region, exec, nixcfg-cmd-screenshot"
        "$mod ALT, 3, Screenshot of window, exec, nixcfg-cmd-screenshot window"
        "$mod ALT, 2, Screenshot of display, exec, nixcfg-cmd-screenshot output"

        # Color picker
        "$mod ALT, 5, Color picker, exec, pkill hyprpicker || hyprpicker -a"
      ];

      # Touchpad gesture bindings for workspace switching
      gesture = [
        "3, horizontal, workspace"
        "3, up, scale: 1.5, fullscreen"
        "3, down, close"
      ];

      bindeld = [
        # Laptop multimedia keys for volume and LCD brightness (with OSD)
        ",XF86AudioRaiseVolume, Volume up, exec, $osdclient --output-volume raise"
        ",XF86AudioLowerVolume, Volume down, exec, $osdclient --output-volume lower"
        ",XF86AudioMute, Mute, exec, $osdclient --output-volume mute-toggle"
        ",XF86AudioMicMute, Mute microphone, exec, $osdclient --input-volume mute-toggle"
        ",XF86MonBrightnessUp, Brightness up, exec, $osdclient --brightness +5"
        ",XF86MonBrightnessDown, Brightness down, exec, $osdclient --brightness -5"

        # Precise 1% multimedia adjustments with Alt modifier
        "ALT, XF86AudioRaiseVolume, Volume up precise, exec, $osdclient --output-volume +1"
        "ALT, XF86AudioLowerVolume, Volume down precise, exec, $osdclient --output-volume -1"
        "ALT, XF86MonBrightnessUp, Brightness up precise, exec, $osdclient --brightness +1"
        "ALT, XF86MonBrightnessDown, Brightness down precise, exec, $osdclient --brightness -1"
      ];
    };
  };
}
