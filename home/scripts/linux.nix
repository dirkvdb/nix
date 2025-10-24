{ pkgs, ... }:
{
  home.packages = [
    # Terminal launcher script
    (pkgs.writeShellScriptBin "nixcfg-launch-terminal" ''
        exec setsid uwsm-app -- "${TERMINAL:-wezterm}" "$@"
    '')

    # Walker launcher script
    # Note: walker service is auto-started by home-manager with runAsService = true
    (pkgs.writeShellScriptBin "nixcfg-launch-walker" ''
      exec walker --width 644 --maxheight 300 --minheight 300 "$@"
    '')

    # Waybar toggle script
    (pkgs.writeShellScriptBin "nixcfg-toggle-waybar" ''
      if ${pkgs.procps}/bin/pgrep -x waybar >/dev/null; then
        ${pkgs.procps}/bin/pkill -x waybar
      else
        uwsm-app -- ${pkgs.waybar}/bin/waybar >/dev/null 2>&1 &
      fi
    '')

    # Get current working directory of active terminal
    (pkgs.writeShellScriptBin "nixcfg-cmd-terminal-cwd" ''
      # Go from current active terminal to its child shell process and run cwd there
      terminal_pid=$(${pkgs.hyprland}/bin/hyprctl activewindow | ${pkgs.gawk}/bin/awk '/pid:/ {print $2}')
      shell_pid=$(${pkgs.procps}/bin/pgrep -P "$terminal_pid" | ${pkgs.coreutils}/bin/tail -n1)

      if [[ -n $shell_pid ]]; then
        cwd=$(${pkgs.coreutils}/bin/readlink -f "/proc/$shell_pid/cwd" 2>/dev/null)

        if [[ -d $cwd ]]; then
          echo "$cwd"
        else
          echo "$HOME"
        fi
      else
        echo "$HOME"
      fi
    '')

    # Launch or focus application
    (pkgs.writeShellScriptBin "nixcfg-launch-or-focus" ''
      app="$1"

      # Check if the app is already running
      if ${pkgs.procps}/bin/pgrep -x "$app" > /dev/null; then
        # Focus the window using hyprctl
        ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "class:$app"
      else
        # Launch the app via uwsm
        uwsm-app -- "$app" &
      fi
    '')

    # Menu launcher
    (pkgs.writeShellScriptBin "nixcfg-menu" ''
        # export PATH="$HOME/.local/share/omarchy/bin:$PATH"

        # Set to true when going directly to a submenu, so we can exit directly
        BACK_TO_EXIT=false

        back_to() {
          local parent_menu="$1"

          if [[ "$BACK_TO_EXIT" == "true" ]]; then
            exit 0
          elif [[ -n "$parent_menu" ]]; then
            "$parent_menu"
          else
            show_main_menu
          fi
        }

        menu() {
          local prompt="$1"
          local options="$2"
          local extra="$3"
          local preselect="$4"

          read -r -a args <<<"$extra"

          if [[ -n "$preselect" ]]; then
            local index
            index=$(echo -e "$options" | grep -nxF "$preselect" | cut -d: -f1)
            if [[ -n "$index" ]]; then
              args+=("-c" "$index")
            fi
          fi

          echo -e "$options" | nixcfg-launch-walker --dmenu --width 295 --minheight 1 --maxheight 600 -p "$prompt..." "''${args[@]}" 2>/dev/null
        }

        # terminal() {
        #   alacritty --class=Omarchy -e "$@"
        # }

        present_terminal() {
          nixcfg-launch-floating-terminal-with-presentation $1
        }

        open_in_editor() {
          notify-send "Editing config file" "$1"
          nixcfg-launch-editor "$1"
        }

        show_trigger_menu() {
          case $(menu "Trigger" "  Capture\n  Share\n󰔎  Toggle") in
          *Capture*) show_capture_menu ;;
          *Share*) show_share_menu ;;
          *Toggle*) show_toggle_menu ;;
          *) show_main_menu ;;
          esac
        }

        show_capture_menu() {
          case $(menu "Capture" "  Screenshot\n  Screenrecord\n󰃉  Color") in
          *Screenshot*) show_screenshot_menu ;;
          *Screenrecord*) show_screenrecord_menu ;;
          *Color*) pkill hyprpicker || hyprpicker -a ;;
          *) show_trigger_menu ;;
          esac
        }

        show_screenshot_menu() {
          case $(menu "Screenshot" "  Snap with Editing\n  Straight to Clipboard") in
          *Editing*) nixcfg-cmd-screenshot smart ;;
          *Clipboard*) nixcfg-cmd-screenshot smart clipboard ;;
          *) show_capture_menu ;;
          esac
        }

        show_screenrecord_menu() {
          case $(menu "Screenrecord" "  Region\n  Region + Audio\n  Display\n  Display + Audio\n  Display + Webcam") in
          *"Region + Audio"*) nixcfg-cmd-screenrecord region --with-audio ;;
          *Region*) nixcfg-cmd-screenrecord ;;
          *"Display + Audio"*) nixcfg-cmd-screenrecord output --with-audio ;;
          *"Display + Webcam"*) nixcfg-cmd-screenrecord output --with-audio --with-webcam ;;
          *Display*) nixcfg-cmd-screenrecord output ;;
          *) back_to show_capture_menu ;;
          esac
        }

        show_share_menu() {
          case $(menu "Share" "  Clipboard\n  File \n  Folder") in
          *Clipboard*) terminal bash -c "nixcfg-cmd-share clipboard" ;;
          *File*) terminal bash -c "nixcfg-cmd-share file" ;;
          *Folder*) terminal bash -c "nixcfg-cmd-share folder" ;;
          *) back_to show_trigger_menu ;;
          esac
        }

        show_toggle_menu() {
          case $(menu "Toggle" "󱄄  Screensaver\n󰔎  Nightlight\n󱫖  Idle Lock\n󰍜  Top Bar") in
          *Screensaver*) nixcfg-toggle-screensaver ;;
          *Nightlight*) nixcfg-toggle-nightlight ;;
          *Idle*) nixcfg-toggle-idle ;;
          *Bar*) nixcfg-toggle-waybar ;;
          *) show_trigger_menu ;;
          esac
        }

        show_system_menu() {
          case $(menu "System" "  Lock\n󱄄  Screensaver\n󰤄  Suspend\n󰜉  Restart\n󰐥  Shutdown") in
          *Lock*) nixcfg-lock-screen ;;
          *Screensaver*) nixcfg-launch-screensaver force ;;
          *Suspend*) systemctl suspend ;;
          *Restart*) nixcfg-state clear re*-required && systemctl reboot --no-wall ;;
          *Shutdown*) nixcfg-state clear re*-required && systemctl poweroff --no-wall ;;
          *) back_to show_main_menu ;;
          esac
        }

        show_main_menu() {
          go_to_menu "$(menu "Go" "󰀻  Apps\n󰧑  Learn\n󱓞  Trigger\n  Style\n  Setup\n󰉉  Install\n󰭌  Remove\n  Update\n  About\n  System")"
        }

        go_to_menu() {
          case "''${1,,}" in
          *apps*) walker -p "Launch..." ;;
          *trigger*) show_trigger_menu ;;
          *share*) show_share_menu ;;
          *screenshot*) show_screenshot_menu ;;
          *screenrecord*) show_screenrecord_menu ;;
          *system*) show_system_menu ;;
          esac
        }

        if [[ -n "$1" ]]; then
          BACK_TO_EXIT=true
          go_to_menu "$1"
        else
          show_main_menu
        fi
    '')
  ];
}
