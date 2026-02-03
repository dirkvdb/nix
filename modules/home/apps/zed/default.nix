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
        "log"
        "neocmake"
        "nix"
        "rainbow-csv"
        "tombi"
      ];

      extraPackages = pkgs.lib.mkIf (!pkgs.stdenv.isDarwin) (
        with pkgs;
        [
          nixd
          biome
          tombi
          color-lsp
          codex-acp
          nixfmt-rfc-style
          just-formatter
          just-lsp
        ]
      );

      userSettings = {
        ui_font_size = 13.0;
        ui_font_family = "RobotoMono Nerd Font Propo";
        vim_mode = true;
        relative_line_numbers = "enabled";

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
          mode = "light";
          light = "Ayu Mirage";
          dark = "Ayu Dark";
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
          codex = {
            default_model = "gpt-5.2/high";
          };
        };
      };

      userKeymaps = [
        {
          context = "Editor";
          bindings = {
            "alt-o" = "editor::SwitchSourceHeader";
            "ctrl-h" = [
              "workspace::ActivatePaneInDirection"
              "Left"
            ];
            "ctrl-l" = [
              "workspace::ActivatePaneInDirection"
              "Right"
            ];
            "ctrl-k" = [
              "workspace::ActivatePaneInDirection"
              "Up"
            ];
            "ctrl-j" = [
              "workspace::ActivatePaneInDirection"
              "Down"
            ];
          };
        }
        {
          context = "Editor && vim_mode == normal";
          bindings = {
            "space e" = "workspace::ToggleLeftDock";
            "space a" = "workspace::ToggleRightDock";
            "space p" = "editor::Format";
            "space g" = "git_panel::ToggleFocus";
            "shift-l" = "pane::ActivateNextItem";
            "shift-h" = "pane::ActivatePrevItem";
            "space v" = "pane::SplitRight";
            "space w" = "pane::CloseActiveItem";
            "space h" = "workspace::ActivateNextPane";
            "space l" = "workspace::ActivatePreviousPane";
          };
        }
        {
          context = "Editor && vim_mode == insert";
          bindings = {
            "alt-h" = "vim::Left";
            "alt-l" = "vim::Right";
            "alt-j" = "vim::Down";
            "alt-k" = "vim::Up";
          };
        }
        {
          context = "Editor && vim_mode == visual";
          bindings = {
            "shift-j" = "editor::MoveLineDown";
            "shift-k" = "editor::MoveLineUp";
            "shift-s" = "vim::PushAddSurrounds";
          };
        }
        {
          context = "ProjectPanel";
          bindings = {
            "space e" = "workspace::ToggleLeftDock";
          };
        }
        {
          context = "Dock";
          bindings = {
            "alt-e" = "editor::ToggleFocus";
            "ctrl-h" = [
              "workspace::ActivatePaneInDirection"
              "Left"
            ];
            "ctrl-l" = [
              "workspace::ActivatePaneInDirection"
              "Right"
            ];
            "ctrl-k" = [
              "workspace::ActivatePaneInDirection"
              "Up"
            ];
            "ctrl-j" = [
              "workspace::ActivatePaneInDirection"
              "Down"
            ];
          };
        }
        {
          context = "vim_mode == normal || ProjectPanel || EmptyPane";
          bindings = {
            "space f" = "file_finder::Toggle";
            "space t" = "project_symbols::Toggle";
            "space s" = "outline::Toggle";
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
            "alt-`" = "terminal_panel::Toggle";
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
