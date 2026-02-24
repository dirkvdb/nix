{
  pkgs,
  unstablePkgs,
  config,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  config = lib.mkIf (!isHeadless) (mkUserHome {
    stylix.targets.zed.enable = false;

    programs.zed-editor = {
      enable = true;
      mutableUserSettings = true;
      package = if pkgs.stdenv.isDarwin then null else unstablePkgs.zed-editor;

      extensions = [
        "biome"
        "cargo-tom"
        "catppuccin-icons"
        "color-highlight"
        "dockerfile"
        "git-firefly"
        "just"
        "glsl"
        "log"
        "neocmake"
        "nix"
        "rainbow-csv"
        "tombi"
        "toml"
      ];

      extraPackages = pkgs.lib.mkIf (!pkgs.stdenv.isDarwin) (
        with unstablePkgs;
        [
          nixd
          biome
          tombi
          color-lsp
          nixfmt-rfc-style
          just-formatter
          just-lsp
          codex-acp
        ]
      );

      userSettings = {
        ui_font_size = 13.0;
        ui_font_family = "RobotoMono Nerd Font Propo";
        vim_mode = true;
        relative_line_numbers = "enabled";

        vim = {
          highlight_on_yank_duration = 500;
        };

        colorize_brackets = true;
        ui_font_features = {
          calt = 0;
        };
        icon_theme = {
          mode = "light";
          light = "Catppuccin Mocha";
          dark = "Catppuccin Mocha";
        };
        title_bar = {
          show_branch_icon = true;
        };
        autosave = "on_focus_change";
        agent = {
          use_modifier_to_send = false;
          default_profile = "write";
          play_sound_when_agent_done = true;
          inline_assistant_model = {
            provider = "copilot_chat";
            model = "claude-sonnet-4.5";
          };
          tool_permissions = {
            default = "allow";
          };
          default_model = {
            provider = "copilot_chat";
            model = "claude-sonnet-4.5";
          };
        };
        edit_predictions = {
          provider = "copilot";
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
        buffer_font_family = theme.codeFont;
        buffer_font_weight = 400.0;
        buffer_font_size = theme.codeFontSize;
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
          font_size = theme.terminalFontSize + 1;
          line_height = "standard";
          font_family = theme.terminalFont;
        };
        theme = {
          mode = "system";
          light = "Ayu Light";
          dark = "Ayu Mirage";
        };
        lsp = {
          tombi = lib.mkMerge [
            {
              binary = {
                arguments = [
                  "lsp"
                  "-v"
                ];
                env = {
                  NO_COLOR = "true";
                };
              };
            }
            (lib.mkIf (!pkgs.stdenv.isDarwin) {
              binary = {
                path = "${unstablePkgs.tombi}/bin/tombi";
              };
            })
          ];
        };
        languages = {
          Python = {
            language_servers = [
              "!basedpyright"
              "!pyright"
              "ty"
              "ruff"
            ];
          };
          Nix = {
            language_servers = [
              "!nil"
              "nixd"
            ];
            formatter = {
              external = {
                command = "nixfmt";
              };
            };
          };
          TOML = {
            formatter = {
              language_server = {
                name = "tombi";
              };
            };
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

        agent_servers = {
          codex = lib.mkMerge [
            {
              default_model = "gpt-5.3-codex/high";
            }
            (lib.mkIf (!pkgs.stdenv.isDarwin) {
              command = "${unstablePkgs.codex-acp}/bin/codex-acp";
            })
          ];
        };
      };

      userKeymaps = [
        {
          context = "Editor";
          bindings = {
            "alt-u" = "editor::SwitchSourceHeader";
            "alt-d" = "editor::SelectNext";
          };
        }
        {
          context = "Editor && vim_mode != insert";
          bindings = {
            "alt-o" = "editor::SelectLargerSyntaxNode";
            "alt-i" = "editor::SelectSmallerSyntaxNode";
            "alt-m" = [
              "workspace::SendKeystrokes"
              "] m z z"
            ];
            "alt-M" = [
              "workspace::SendKeystrokes"
              "[ m z z"
            ];
          };
        }
        {
          context = "Workspace || Editor";
          bindings = {
            "ctrl-h" = "workspace::ActivatePaneLeft";
            "ctrl-l" = "workspace::ActivatePaneRight";
            "ctrl-k" = "workspace::ActivatePaneUp";
            "ctrl-j" = "workspace::ActivatePaneDown";
            "alt-h" = "workspace::ToggleLeftDock";
            "alt-l" = "workspace::ToggleRightDock";
            "alt-j" = "workspace::ToggleBottomDock";
          };
        }
        {
          context = "vim_mode == normal";
          bindings = {
            "space p" = "editor::Format";
            "space g" = "git_panel::ToggleFocus";
            "shift-l" = "pane::ActivateNextItem";
            "shift-h" = "pane::ActivatePreviousItem";
            "space v" = "pane::SplitRight";
            "space w" = "pane::CloseActiveItem";
            "space h" = "workspace::ActivateNextPane";
            "space l" = "workspace::ActivatePreviousPane";
          };
        }
        {
          context = "vim_mode == visual";
          bindings = {
            "shift-j" = "editor::MoveLineDown";
            "shift-k" = "editor::MoveLineUp";
            "shift-s" = "vim::PushAddSurrounds";
          };
        }
        {
          context = "Dock";
          bindings = {
            "alt-e" = "editor::ToggleFocus";
          };
        }
        {
          context = "Terminal";
          bindings = {
            "ctrl-shift-h" = "pane::ActivatePreviousItem";
            "ctrl-shift-l" = "pane::ActivateNextItem";
            "alt-`" = "editor::ToggleFocus";
          };
        }
        {
          context = "Workspace && !Terminal";
          bindings = {
            "alt-`" = "terminal_panel::ToggleFocus";
          };
        }
        {
          context = "(VimControl && !menu)";
          bindings = {
            "ctrl-d" = [
              "workspace::SendKeystrokes"
              "ctrl-d z z"
            ];
            "ctrl-u" = [
              "workspace::SendKeystrokes"
              "ctrl-u z z"
            ];
          };
        }
        {
          context = "(vim_mode == normal && !Terminal) || GitPanel";
          bindings = {
            "space f" = "file_finder::Toggle";
            "space S" = "project_symbols::Toggle";
            "space s" = "outline::Toggle";
            "space k" = "workspace::ToggleZoom";
          };
        }
        {
          context = "Editor && vim_mode == insert && !VimWaiting";
          bindings = {
            "j k" = [
              "workspace::SendKeystrokes"
              "escape : w enter"
            ];
          };
        }
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
            "secondary-shift-b" = [
              "task::Spawn"
              {
                task_name = "Build project";
                reveal_target = "dock";
              }
            ];
            "secondary-shift-y" = [
              "task::Spawn"
              {
                task_name = "Run project";
                reveal_target = "dock";
              }
            ];
          };
        }
        {
          context = "vim_operator == a || vim_operator == i || vim_operator == cs";
          bindings = {
            # Traditional Vim behavior
            # q = "vim::AnyQuotes";
            # b = "vim::AnyBrackets";

            # mini.ai plugin behavior
            q = "vim::MiniQuotes";
            b = "vim::MiniBrackets";
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
  });
}
