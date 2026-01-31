{
  config,
  lib,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;

  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable or false;
  isHeadless = config.local.headless or false;
  hasAmdGpu = config.local.system.video.amd.enable;
  # Get CPU core count from system config
  cpuCores = config.local.system.cpu.cores;
  # Generate CPU icon placeholders based on core count
  cpuIconPlaceholders = lib.concatStrings (lib.genList (i: "{icon${toString i}}") cpuCores);
  # Set waybar height based on hostname (32 for macbook-pro due to notch, 26 for others)
  hostname = config.local.system.network.hostname or "";
  waybarHeight = if hostname == "macbook-pro" then 32 else 26;
  mkUserHome = mkHome user.name;
in
{
  config = lib.mkIf (isLinux && isDesktop && !isHeadless) (mkUserHome {
    # Configure waybar with systemd service
    programs.waybar = {
      enable = true;
      systemd = {
        enable = true;
        target = "hyprland-session.target";
      };
      style = ''
        @define-color foreground ${theme.uiAccentColor};
        @define-color background ${theme.uiBaseColor};

        * {
            background-color: @background;
            color: @foreground;

            border: none;
            border-radius: 0;
            min-height: 0;
            font-family: "RobotoMono Nerd Font Propo";
            font-weight: 600;
            font-size: 12px;
        }

        .modules-left {
            margin-left: 8px;
        }

        .modules-right {
            margin-right: 8px;
        }

        #workspaces button {
            all: initial;
            background-color: transparent;
            color: @foreground;
            padding: 0 6px;
            margin: 0 1.5px;
            min-width: 9px;
        }

        #workspaces button.empty {
            opacity: 0.5;
        }

        #cpu,
        #memory,
        #battery,
        #pulseaudio,
        #custom-omarchy,
        #custom-screenrecording-indicator,
        #custom-update {
            min-width: 12px;
            margin: 0 7.5px;
        }

        #tray {
            margin-right: 16px;
        }

        #bluetooth {
            margin-right: 17px;
        }

        #network {
            margin-right: 13px;
        }

        #custom-expand-icon {
            margin-right: 20px;
        }

        tooltip {
            margin: 0;
            padding: 0;
            border: none;
            background-color: transparent;
        }

        tooltip.background {
            background-color: transparent;
            border: none;
        }

        tooltip * {
            background-color: transparent;
        }

        tooltip label {
            margin: 0;
            padding: 3px 6px;
            border: 1px solid @foreground;
            border-radius: 6px;
            background-color: @background;
            color: @foreground;
        }

        window.popup {
            background-color: transparent;
        }

        menu {
            background-color: @background;
            border: 1px solid @foreground;
            border-radius: 6px;
            padding: 4px 0;
        }

        menu > .background {
            background-color: @background;
            border-radius: 6px;
        }

        menu * {
            background-color: transparent;
        }

        menu menuitem {
            padding: 4px 10px;
            border-radius: 4px;
        }

        menu menuitem:hover,
        menu menuitem:selected {
            background-color: alpha(@foreground, 0.12);
        }

        #custom-update {
            font-size: 10px;
        }

        #clock {
            margin-left: 8.75px;
        }

        .hidden {
            opacity: 0;
        }

        #custom-screenrecording-indicator {
            min-width: 12px;
            margin-left: 8.75px;
            font-size: 10px;
        }

        #custom-screenrecording-indicator.active {
            color: #a55555;
        }
      '';
      settings = [
        {
          reload_style_on_change = true;
          layer = "top";
          position = "top";
          spacing = 0;
          height = waybarHeight;
          modules-left = [
            "custom/nixmenu"
            "hyprland/workspaces"
          ]
          ++ lib.optionals (hostname == "macbook-pro") [ "clock" ];
          modules-center = lib.optionals (hostname != "macbook-pro") [ "clock" ];
          modules-right = [
            "cpu"
            "memory"
          ]
          ++ lib.optionals hasAmdGpu [
            "custom/gpuusage"
            "custom/gpumemory"
          ]
          ++ [
            "tray"
            "battery"
            "bluetooth"
            "network"
            "pulseaudio"
          ];

          "hyprland/workspaces" = {
            on-click = "activate";
            format = "{icon}";
            format-icons = {
              default = "";
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              active = "󱓻";
            };
            persistent-workspaces = {
              "1" = [ ];
              "2" = [ ];
              "3" = [ ];
              "4" = [ ];
              "5" = [ ];
              "6" = [ ];
              "7" = [ ];
              "8" = [ ];
            };
          };

          "custom/nixmenu" = {
            format = "<span font='omarchy'></span>";
            tooltip = false;
            on-click = "nixcfg-launch-walker";
            on-click-right = "nixcfg-launch-terminal";
          };

          cpu = {
            interval = 2;
            format = "  ${cpuIconPlaceholders}";
            format-icons = [
              "<span> </span>"
              "<span color='#a7c080'>▁</span>"
              "<span color='#a7c080'>▂</span>"
              "<span color='#83c092'>▃</span>"
              "<span color='#83c092'>▄</span>"
              "<span color='#dbbc7f'>▅</span>"
              "<span color='#dbbc7f'>▆</span>"
              "<span color='#e69875'>▇</span>"
              "<span color='#e67e80'>█</span>"
            ];
            on-click = "xdg-terminal-exec -- btop";
          };

          memory = {
            interval = 2;
            format = "󰍛 {percentage}%";
            tooltip-format = "{used:0.1f}GiB / {total:0.1f}GiB used";
            on-click = "xdg-terminal-exec -- btop";
          };

          "custom/gpumemory" = {
            format = " {}% ";
            interval = 5;
            exec = "nixcfg-gpu-memory";
            return-type = "json";
            on-click = "xdg-terminal-exec -- btop";
          };

          "custom/gpuusage" = {
            interval = 2;
            exec = "nixcfg-gpu-usage";
            return-type = "json";
            format = "{icon} ";
            format-icons = [
              "<span> </span>"
              "<span color='#a7c080'>▁</span>"
              "<span color='#a7c080'>▂</span>"
              "<span color='#83c092'>▃</span>"
              "<span color='#83c092'>▄</span>"
              "<span color='#dbbc7f'>▅</span>"
              "<span color='#dbbc7f'>▆</span>"
              "<span color='#e69875'>▇</span>"
              "<span color='#e67e80'>█</span>"
            ];
            on-click = "xdg-terminal-exec -- btop";
          };

          clock = {
            format = "{:L%d %b %H:%M}";
            format-alt = "{:L%d %B W%V %Y}";
            tooltip = false;
          };

          network = {
            format-icons = [
              "󰤯"
              "󰤟"
              "󰤢"
              "󰤥"
              "󰤨"
            ];
            format = "{icon}";
            format-wifi = "{icon}";
            format-ethernet = "󰀂";
            format-disconnected = "󰤮";
            tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            tooltip-format-disconnected = "Disconnected";
            interval = 3;
            spacing = 1;
            on-click = "nixcfg-launch-wifi";
          };

          battery = {
            format = "{capacity}% {icon}";
            format-discharging = "{icon}";
            format-charging = "{icon}";
            format-plugged = "";
            format-icons = {
              charging = [
                "󰢜"
                "󰂆"
                "󰂇"
                "󰂈"
                "󰢝"
                "󰂉"
                "󰢞"
                "󰂊"
                "󰂋"
                "󰂅"
              ];
              default = [
                "󰁺"
                "󰁻"
                "󰁼"
                "󰁽"
                "󰁾"
                "󰁿"
                "󰂀"
                "󰂁"
                "󰂂"
                "󰁹"
              ];
            };
            format-full = "󰂅";
            tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
            tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
            interval = 5;
            on-click = "nixcfg-menu power";
            states = {
              warning = 20;
              critical = 10;
            };
          };

          bluetooth = {
            format = "󰂯";
            format-disabled = "󰂲";
            format-connected = "󰂱";
            tooltip-format = "Devices connected: {num_connections}";
            on-click = "overskride";
          };

          pulseaudio = {
            format = "{icon}";
            on-click = "xdg-terminal-exec --app-id=TUI.float -- wiremix";
            on-click-right = "pamixer -t";
            tooltip-format = "Playing at {volume}%";
            scroll-step = 5;
            format-muted = "";
            format-icons = {
              default = [
                ""
                ""
                ""
              ];
            };
          };

          "group/tray-expander" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 600;
              children-class = "tray-group-item";
            };
            modules = [
              "custom/expand-icon"
              "tray"
            ];
          };

          "custom/expand-icon" = {
            format = " ";
            tooltip = false;
          };

          tray = {
            icon-size = 12;
            spacing = 12;
          };
        }
      ];
    };
  });
}
