{ pkgs, config, ... }:
let
  inherit (config.local) user;
in
{
  home-manager.users.${user.name} = {
    programs.zed-editor = {
      enable = true;
      extensions = [
        "biome"
        "cargo-tom"
        "catppuccin-icons"
        "color-highlight"
        "dockerfile"
        "git-firefly"
        "just"
        "log"
        "neocmake"
        "nix"
        "rainbow-csv"
        "tombi"
      ];
      extraPackages = with pkgs; [
        nil
        nixd
        biome
      ];

      userSettings = {
        #ui_font_family = "Roboto";
        vim_mode = false;
        ui_font_features = {
          calt = 0;
        };
        icon_theme = {
          mode = "system";
          light = "Catppuccin Mocha";
          dark = "Catppuccin Mocha";
        };
        title_bar = {
          show_branch_icon = true;
        };
        autosave = "on_focus_change";
        agent = {
          use_modifier_to_send = true;
          default_profile = "write";
          play_sound_when_agent_done = true;
          inline_assistant_model = {
            provider = "copilot_chat";
            model = "claude-sonnet-4.5";
          };
          always_allow_tool_actions = true;
          default_model = {
            provider = "copilot_chat";
            model = "claude-sonnet-4.5";
          };
        };
        features = {
          edit_prediction_provider = "copilot";
        };
        git = {
          inline_blame = {
            enabled = false;
          };
        };
        gutter = {
          folds = false;
          min_line_number_digits = 3;
        };
        project_panel = {
          hide_gitignore = true;
          entry_spacing = "standard";
          indent_size = 13;
          indent_guides = {
            show = "always";
          };
        };
        telemetry = {
          metrics = false;
        };
        ui_font_size = 15.0;
        buffer_font_family = "CaskaydiaMono Nerd Font Mono";
        buffer_font_weight = 600.0;
        buffer_font_size = 14;
        buffer_font_features = {
          liga = true;
        };
        tab_bar = {
          show_nav_history_buttons = false;
        };
        outline_panel = {
          dock = "right";
        };
        terminal = {
          dock = "bottom";
          font_size = 13;
          line_height = "standard";
          font_family = "FiraMono Nerd Font Mono";
        };
        theme = {
          mode = "system";
          light = "Ayu Mirage";
          dark = "Ayu Dark";
        };
        languages = {
          Python = {
            language_servers = [
              "pyright"
              "ruff"
            ];
          };
          Nix = {
            language_servers = [
              "nil"
              "nixd"
            ];
          };
        };
        diagnostics = {
          inline = {
            enabled = true;
          };
        };
        profiles = {
          laptop = {
            buffer_font_size = 14;
            ui_font_size = 14;
            terminal = pkgs.lib.mkIf pkgs.stdenv.isDarwin {
              shell = {
                program = "nu";
              };
              env = {
                XDG_CONFIG_HOME = "/Users/dirk/.config";
              };
            };
          };
          presentation = {
            buffer_font_size = 20;
            ui_font_size = 18;
          };
        };
        lsp = {
          nil = {
            settings = {
              nil = {
                nix = {
                  flake = {
                    autoArchive = true;
                  };
                };
              };
            };
          };
        };
      };

      userKeymaps = [
        {
          context = "Workspace";
          bindings = {
            "secondary-shift-t" = [
              "task::Spawn"
              {
                task_name = "Test project";
                reveal_target = "dock";
              }
            ];
          };
        }
        {
          context = "Workspace";
          bindings = {
            "secondary-shift-b" = [
              "task::Spawn"
              {
                task_name = "Build project";
                reveal_target = "dock";
              }
            ];
          };
        }
        {
          bindings = {
            "alt-o" = "editor::SwitchSourceHeader";
          };
        }
      ];

      userTasks = [
        {
          label = "Build project";
          command = "just";
          args = [ "build" ];
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
        }
        {
          label = "Test project";
          command = "just";
          args = [ "test" ];
          env = {
            RUST_BACKTRACE = "1";
          };
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
        }
        {
          label = "Test project in debug mode";
          command = "just";
          args = [ "test_debug" ];
          env = {
            RUST_LOG = "emission_inventory_framework=debug";
            RUST_BACKTRACE = "1";
          };
          use_new_terminal = false;
          allow_concurrent_runs = false;
          reveal = "always";
        }
      ];
    };
  };
}
