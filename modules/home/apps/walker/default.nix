{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
  isDesktop = config.local.desktop.enable or false;
in
{
  config = lib.mkIf isDesktop (mkUserHome {
    services.elephant = {
      enable = true;
      settings = {
        launch_prefix = "uwsm app --";
      };
    };
    services.walker = {
      enable = true;
      systemd.enable = true;
      settings = {
        force_keyboard_focus = true;
        close_when_open = true;
        selection_wrap = true;
        click_to_close = true;
        global_argument_delimiter = "#";
        exact_search_prefix = "'";
        disable_mouse = false;
        theme = "apps";
        additional_theme_location = "~/.local/share/theme/walker";

        shell = {
          anchor_top = true;
          anchor_bottom = true;
          anchor_left = true;
          anchor_right = true;
        };

        placeholders = {
          default = {
            input = " Search...";
            list = "No Results";
          };
        };

        keybinds = {
          quick_activate = [ ];
        };

        providers = {
          default = [
            "desktopapplications"
            "menus"
            "websearch"
          ];
          empty = [ "desktopapplications" ];
          max_results = 50;
          sets = { };
          max_results_provider = { };
          prefixes = [
            {
              prefix = "/";
              provider = "providerlist";
            }
            {
              prefix = ".";
              provider = "files";
            }
            {
              prefix = ":";
              provider = "symbols";
            }
            {
              prefix = "=";
              provider = "calc";
            }
            {
              prefix = "@";
              provider = "websearch";
            }
            {
              prefix = "$";
              provider = "clipboard";
            }
          ];
        };

        emergencies = [
          {
            text = "Restart Walker";
            command = "omarchy-restart-walker";
          }
        ];

        providerlist = [
          {
            action = "activate";
            default = true;
            bind = "Return";
            after = "ClearReload";
          }
        ];

        calc = [
          {
            action = "copy";
            default = true;
            bind = "Return";
          }
          {
            action = "delete";
            bind = "ctrl d";
            after = "AsyncReload";
          }
          {
            action = "save";
            bind = "ctrl s";
            after = "AsyncClearReload";
          }
        ];

        websearch = [
          {
            action = "search";
            default = true;
            bind = "Return";
          }
          {
            action = "erase_history";
            label = "clear hist";
            bind = "ctrl h";
            after = "Reload";
          }
        ];

        desktopapplications = [
          {
            action = "start";
            default = true;
            bind = "Return";
          }
          {
            action = "start:keep";
            label = "open+next";
            bind = "shift Return";
            after = "KeepOpen";
          }
          {
            action = "erase_history";
            label = "clear hist";
            bind = "ctrl h";
            after = "AsyncReload";
          }
          {
            action = "pin";
            bind = "ctrl p";
            after = "AsyncReload";
          }
          {
            action = "unpin";
            bind = "ctrl p";
            after = "AsyncReload";
          }
          {
            action = "pinup";
            bind = "ctrl n";
            after = "AsyncReload";
          }
          {
            action = "pindown";
            bind = "ctrl m";
            after = "AsyncReload";
          }
        ];

        files = [
          {
            action = "open";
            default = true;
            bind = "Return";
          }
          {
            action = "opendir";
            label = "open dir";
            bind = "ctrl Return";
          }
          {
            action = "copypath";
            label = "copy path";
            bind = "ctrl shift c";
          }
          {
            action = "copyfile";
            label = "copy file";
            bind = "ctrl c";
          }
        ];

        runner = [
          {
            action = "run";
            default = true;
            bind = "Return";
          }
          {
            action = "runterminal";
            label = "run in terminal";
            bind = "shift Return";
          }
          {
            action = "erase_history";
            label = "clear hist";
            bind = "ctrl h";
            after = "Reload";
          }
        ];

        symbols = [
          {
            action = "run_cmd";
            label = "select";
            default = true;
            bind = "Return";
          }
          {
            action = "erase_history";
            label = "clear hist";
            bind = "ctrl h";
            after = "Reload";
          }
        ];

        unicode = [
          {
            action = "run_cmd";
            label = "select";
            default = true;
            bind = "Return";
          }
          {
            action = "erase_history";
            label = "clear hist";
            bind = "ctrl h";
            after = "Reload";
          }
        ];

        clipboard = [
          {
            action = "copy";
            default = true;
            bind = "Return";
          }
          {
            action = "remove";
            bind = "ctrl d";
            after = "ClearReload";
          }
          {
            action = "remove_all";
            global = true;
            label = "clear";
            bind = "ctrl shift d";
            after = "ClearReload";
          }
          {
            action = "toggle_images";
            global = true;
            label = "toggle images";
            bind = "ctrl i";
            after = "ClearReload";
          }
          {
            action = "edit";
            bind = "ctrl o";
          }
        ];
      };
    };
  });
}
