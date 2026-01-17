{ pkgs, config, ... }:
let
  # Use the chromium package with WideVine support from home-manager config
  chromiumPkg = config.programs.chromium.package;
in
{
  home.packages = [
    # convet tabular geospatial files to sqlite format for easier inspection
    (pkgs.writeShellScriptBin "geo-to-sqlite" ''
      set -euo pipefail

      if [ "$#" -ne 1 ]; then
          echo "Usage: geo-to-sqlite <input-file>"
          exit 1
      fi

      input="$1"

      # Strip extension (if any) and add .sqlite
      base="$(basename "$input")"
      dir="$(dirname "$input")"
      name_without_ext="''${base%.*}"
      output="$dir/$name_without_ext.db"

      nix-shell -p gdal --run "ogr2ogr -f SQLite \"$output\" \"$input\""
    '')

    (pkgs.writeShellScriptBin "worktunnel" ''
      autossh -f -M 0 -o "ServerAliveInterval 10" -D localhost:1080 -N vito
    '')

    (pkgs.writeShellScriptBin "workbrowser" ''
      vivaldi --proxy-server=socks5://localhost:1080
    '')

    # Terminal launcher script
    (pkgs.writeShellScriptBin "nixcfg-launch-terminal" ''
      exec setsid xdg-terminal-exec -- "$@"
    '')

    # Walker launcher script
    # Note: walker service is auto-started by home-manager with runAsService = true
    (pkgs.writeShellScriptBin "nixcfg-launch-walker" ''
      exec walker --width 644 --maxheight 300 --minheight 300 "$@"
    '')

    (pkgs.writeShellScriptBin "nixcfg-launch-webapp" ''
      exec setsid ${chromiumPkg}/bin/chromium --app="$1" "''${@:2}"
    '')

    (pkgs.writeShellScriptBin "nixcfg-launch-or-focus-webapp" ''
      if (($# == 0)); then
        echo "Usage: nixcfg-launch-or-focus-webapp [window-pattern] [url-and-flags...]"
        exit 1
      fi

      WINDOW_PATTERN="$1"
      shift
      LAUNCH_COMMAND="nixcfg-launch-webapp $@"

      exec nixcfg-launch-or-focus "$WINDOW_PATTERN" "$LAUNCH_COMMAND"
    '')

    (pkgs.writeShellScriptBin "nixcfg-launch-or-focus" ''
      if (($# == 0)); then
        echo "Usage: nixcfg-launch-or-focus [window-pattern] [launch-command]"
        exit 1
      fi

      WINDOW_PATTERN="$1"
      LAUNCH_COMMAND="''${2:- $WINDOW_PATTERN}"
      WINDOW_ADDRESS=$(hyprctl clients -j | jq -r --arg p "$WINDOW_PATTERN" '.[]|select((.class|test("\\b" + $p + "\\b";"i")) or (.title|test("\\b" + $p + "\\b";"i")))|.address' | head -n1)

      if [[ -n $WINDOW_ADDRESS ]]; then
        hyprctl dispatch focuswindow "address:$WINDOW_ADDRESS"
      else
        eval exec $LAUNCH_COMMAND
      fi
    '')

    # Waybar toggle script
    (pkgs.writeShellScriptBin "nixcfg-toggle-waybar" ''
      if systemctl --user is-active --quiet waybar.service; then
        systemctl --user stop waybar.service
        notify-desktop "Waybar stopped"
      else
        systemctl --user start waybar.service
        notify-desktop "Waybar started"
      fi
    '')

    # Make sure config changes get applied for apps that do not auto-reload
    (pkgs.writeShellScriptBin "nixcfg-reload" ''
      systemctl --user restart waybar.service
      systemctl --user restart elephant.service
      systemctl --user restart walker.service
    '')

    (pkgs.writeShellScriptBin "nixcfg-lock-screen" ''
      hyprlock
    '')

    # Toggle idle lock
    (pkgs.writeShellScriptBin "nixcfg-toggle-idle" ''
      if systemctl --user is-active --quiet hypridle.service; then
        systemctl --user stop hypridle.service
        notify-desktop "Stop locking computer when idle"
      else
      systemctl --user start hypridle.service
        notify-desktop "Now locking computer when idle"
      fi
    '')

    # Toggle nightlight
    (pkgs.writeShellScriptBin "nixcfg-toggle-nightlight" ''
      if [ "$(sunsetr get transition_mode)" = "geo" ]; then
        sunsetr preset day
        notify-desktop "   Daylight screen temperature"
      else
        sunsetr preset day
        notify-desktop "  Nightlight screen temperature"
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

    # Launch or the wifi selection
    (pkgs.writeShellScriptBin "nixcfg-launch-wifi" ''
      xdg-terminal-exec --app-id=TUI.float -- impala "$@"
    '')

    (pkgs.writeShellScriptBin "nixcfg-gpu-usage" ''
      GPU_BUSY_FILE="/sys/class/drm/card1/device/gpu_busy_percent"
      if [[ -r "$GPU_BUSY_FILE" ]]; then
          percent=$(<"$GPU_BUSY_FILE")
      else
          exit 1
      fi

      printf '{"text":"%d","tooltip":"GPU %d%%","percentage":%d}' $percent $percent $percent
    '')

    (pkgs.writeShellScriptBin "nixcfg-gpu-memory" ''
      GPU_PATH="/sys/class/drm/card1/device"
      GPU_TOTAL_MEM="$GPU_PATH/mem_info_vram_total"
      GPU_USED_MEM="$GPU_PATH/mem_info_vram_used"
      if [[ -r "$GPU_PATH" ]]; then
          total_bytes=$(<"$GPU_TOTAL_MEM")
          used_bytes=$(<"$GPU_USED_MEM")

          # Convert to MiB first to avoid overflow, then calculate GiB * 10 for one decimal
          total_mib=$(( total_bytes / 1024 / 1024 ))
          used_mib=$(( used_bytes / 1024 / 1024 ))
          total=$(( total_mib * 10 / 1024 ))
          used=$(( used_mib * 10 / 1024 ))

          percentage=$(( used_bytes * 100 / total_bytes ))
      else
          exit 1
      fi

      awk -v pct="$percentage" -v used="$used" -v total="$total" \
        'BEGIN {printf "{\"text\":\"%d\",\"tooltip\":\"%.1fGib / %.1fGib used\",\"percentage\":%d}", pct, used/10, total/10, pct}'
    '')

    (pkgs.writeShellScriptBin "nixcfg-cmd-share" ''
      if (($# == 0)); then
        echo "Usage: nixcfg-cmd-share [clipboard|file|folder]"
        exit 1
      fi

      MODE="$1"
      shift

      if [[ $MODE == "clipboard" ]]; then
        TEMP_FILE=$(mktemp --suffix=.txt)
        wl-paste >"$TEMP_FILE"
        FILES="$TEMP_FILE"
      else
        if (($# > 0)); then
          FILES="$*"
        else
          if [[ $MODE == "folder" ]]; then
            # Pick a single folder from home directory
            FILES=$(find "$HOME" -type d 2>/dev/null | fzf)
          else
            # Pick one or more files from home directory
            FILES=$(find "$HOME" -type f 2>/dev/null | fzf --multi)
          fi
          [ -z "$FILES" ] && exit 0
        fi
      fi

      # Run LocalSend in its own systemd service (detached from terminal)
      # Convert newline-separated files to space-separated arguments
      if [[ $MODE != "clipboard" ]] && echo "$FILES" | grep -q $'\n'; then
        # Multiple files selected - convert newlines to array
        readarray -t FILE_ARRAY <<<"$FILES"
        systemd-run --user --quiet --collect localsend_app --headless send "''${FILE_ARRAY[@]}"
      else
        # Single file or clipboard mode
        systemd-run --user --quiet --collect localsend_app --headless send "$FILES"
      fi

      # Note: Temporary file will remain until system cleanup for clipboard mode
      # This ensures the file content is available for the LocalSend GUI

      exit 0
    '')

    (pkgs.writeShellScriptBin "nixcfg-cmd-screenshot" ''
      [[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
      OUTPUT_DIR="''${NIXCFG_SCREENSHOT_DIR:-''${XDG_PICTURES_DIR:-$HOME/Pictures}}"

      if [[ ! -d "$OUTPUT_DIR" ]]; then
        notify-desktop "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
        exit 1
      fi

      pkill slurp && exit 0

      MODE="''${1:-smart}"
      PROCESSING="''${2:-slurp}"

      get_rectangles() {
        local active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
        hyprctl monitors -j | jq -r --arg ws "$active_workspace" '.[] | select(.activeWorkspace.id == ($ws | tonumber)) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'
        hyprctl clients -j | jq -r --arg ws "$active_workspace" '.[] | select(.workspace.id == ($ws | tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
      }

      # Select based on mode
      case "$MODE" in
        region)
          wayfreeze & PID=$!
          sleep .1
          SELECTION=$(slurp 2>/dev/null)
          kill $PID 2>/dev/null
          ;;
        windows)
          wayfreeze & PID=$!
          sleep .1
          SELECTION=$(get_rectangles | slurp -r 2>/dev/null)
          kill $PID 2>/dev/null
          ;;
        fullscreen)
          SELECTION=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"')
          ;;
        smart|*)
          RECTS=$(get_rectangles)
          wayfreeze & PID=$!
          sleep .1
          SELECTION=$(echo "$RECTS" | slurp 2>/dev/null)
          kill $PID 2>/dev/null

          # If the selction area is L * W < 20, we'll assume you were trying to select whichever
          # window or output it was inside of to prevent accidental 2px snapshots
          if [[ "$SELECTION" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
            if (( ''${BASH_REMATCH[3]} * ''${BASH_REMATCH[4]} < 20 )); then
              click_x="''${BASH_REMATCH[1]}"
              click_y="''${BASH_REMATCH[2]}"

              while IFS= read -r rect; do
                if [[ "$rect" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
                  rect_x="''${BASH_REMATCH[1]}"
                  rect_y="''${BASH_REMATCH[2]}"
                  rect_width="''${BASH_REMATCH[3]}"
                  rect_height="''${BASH_REMATCH[4]}"

                  if (( click_x >= rect_x && click_x < rect_x+rect_width && click_y >= rect_y && click_y < rect_y+rect_height )); then
                    SELECTION="''${rect_x},''${rect_y} ''${rect_width}x''${rect_height}"
                    break
                  fi
                fi
              done <<< "$RECTS"
            fi
          fi
          ;;
      esac

      [ -z "$SELECTION" ] && exit 0

      if [[ $PROCESSING == "slurp" ]]; then
      grim -g "$SELECTION" - |
        satty --filename - \
          --output-filename "$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" \
          --early-exit \
          --actions-on-enter save-to-clipboard \
          --save-after-copy \
          --copy-command 'wl-copy'
      else
        grim -g "$SELECTION" - | wl-copy
      fi
    '')

    (pkgs.writeShellScriptBin "nixcfg-powerprofiles-list" ''
      powerprofilesctl list |
        awk '/^\s*[* ]\s*[a-zA-Z0-9\-]+:$/ { gsub(/^[*[:space:]]+|:$/,""); print }' |
        tac
    '')

    # Menu launcher
    (pkgs.writeShellScriptBin "nixcfg-menu" ''
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

      terminal() {
        xdg-terminal-exec --app-id=NixCfg -- "$@"
      }

      present_terminal() {
        nixcfg-launch-floating-terminal-with-presentation $1
      }

      open_in_editor() {
        notify-desktop "Editing config file" "$1"
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

      show_setup_power_menu() {
        profile=$(menu "Power Profile" "$(nixcfg-powerprofiles-list)" "" "$(powerprofilesctl get)")

        if [[ "$profile" == "CNCLD" || -z "$profile" ]]; then
          back_to show_setup_menu
        else
          powerprofilesctl set "$profile"
        fi
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
        *Restart*) systemctl reboot --no-wall ;;
        *Shutdown*) systemctl poweroff --no-wall ;;
        *) back_to show_main_menu ;;
        esac
      }

      show_main_menu() {
        go_to_menu "$(menu "Go" "󰀻  Apps\n󱓞  Trigger\n  System")"
      }

      go_to_menu() {
        case "''${1,,}" in
        *apps*) walker -p "Launch..." ;;
        *trigger*) show_trigger_menu ;;
        *share*) show_share_menu ;;
        *power*) show_setup_power_menu ;;
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
