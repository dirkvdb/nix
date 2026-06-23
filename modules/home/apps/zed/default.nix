{
  pkgs,
  unstablePkgs,
  config,
  lib,
  mkHome,
  ...
}:
let
  cfg = config.local.apps.zed;
  npuCfg = config.hardware.amd-npu or { };
  lemonadeEnabled = (npuCfg.enable or false) && (npuCfg.enableLemonade or false);
  lemonadePort = (npuCfg.lemonade or { }).port or 13305;
  inherit (config.local) user;
  inherit (config.local) theme;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
  zedPinnedVersion = "1.7.2";

  zedEditorPinned = unstablePkgs.zed-editor.overrideAttrs (old: rec {
    version = zedPinnedVersion;
    doCheck = false;
    src = unstablePkgs.fetchFromGitHub {
      owner = "zed-industries";
      repo = "zed";
      tag = "v${version}";
      hash = "sha256-f4CxfUsOEZQIIf0+v+3nXH4zlM3mPy/eZyzXG1ayiVc=";
    };
    cargoDeps = unstablePkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "${old.pname}-${version}";
      hash = "sha256-QTnDiNFrBl8E6BgFL1HjoJhGfMBUzOoMimkyKdwUcks=";
    };
    env = (old.env or { }) // {
      NIX_CFLAGS_COMPILE = lib.concatStringsSep " " [
        (old.env.NIX_CFLAGS_COMPILE or "")
        "-march=native"
      ];
    };
  });
in
{
  options.local.apps.zed = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Zed editor configuration.";
    };

    useLatestUpstream = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use the pinned upstream Zed version when newer than unstable.";
    };

    localModels = lib.mkEnableOption "local model providers in Zed (e.g. lemonade)";

    mimeTypes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "text/plain"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++src"
        "text/x-python"
        "text/x-rust"
        "text/x-go"
        "text/x-java"
        "text/javascript"
        "application/json"
        "application/x-yaml"
        "application/toml"
        "text/markdown"
        "text/x-nix"
      ];
      description = "MIME types for which Zed is the default handler.";
    };

    lemonade.models = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          name = "gemma4-it-e4b-FLM";
          display_name = "Gemma 4 IT e4b (FLM)";
          max_tokens = 100000;
        }
        {
          name = "qwen3.5-9b-FLM";
          display_name = "Qwen 3.5 9B (FLM)";
          max_tokens = 100000;
        }
      ];
      description = "Models to expose from the local lemonade server in Zed.";
    };
  };

  config = lib.mkIf (cfg.enable) (mkUserHome {
    xdg.mimeApps.defaultApplications = lib.genAttrs cfg.mimeTypes (_: "dev.zed.Zed.desktop");

    stylix.targets.zed.enable = false;

    programs.zed-editor = {
      enable = true;
      mutableUserSettings = true;
      package =
        if pkgs.stdenv.isDarwin || isHeadless then
          null
        else if
          cfg.useLatestUpstream && !(lib.versionOlder zedPinnedVersion unstablePkgs.zed-editor.version)
        then
          zedEditorPinned
        else
          unstablePkgs.zed-editor;

      extensions = [
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
        "groovy"
      ];

      extraPackages = pkgs.lib.mkIf (!pkgs.stdenv.isDarwin) (
        with unstablePkgs;
        [
          nixd
          tombi
          color-lsp
          nixfmt-rs
          just-formatter
          just-lsp
          bash-language-server
          shellcheck
          codex-acp
          groovy-language-server
          mcp-nixos
        ]
      );

      userSettings = lib.mkMerge [
        (lib.mkIf (cfg.localModels && lemonadeEnabled) {
          language_models = {
            openai_compatible = {
              lemonade = {
                api_url = "http://localhost:${toString lemonadePort}/api/v0";
                available_models = cfg.lemonade.models;
              };
            };
          };
        })
        {
          cli_default_open_behavior = "new_window";
          vim_mode = true;
          vim = {
            highlight_on_yank_duration = 500;
          };
          relative_line_numbers = "enabled";
          autosave = "on_focus_change";
          colorize_brackets = true;
          scroll_sensitivity = 3.0;

          ui_font_size = 13.0;
          ui_font_family = "RobotoMono Nerd Font Propo";
          ui_font_features = {
            calt = 0;
          };

          icon_theme = {
            mode = "light";
            light = "Catppuccin Mocha";
            dark = "Catppuccin Mocha";
          };

          title_bar = {
            show_branch_status_icon = true;
          };

          collaboration_panel = {
            dock = "left";
          };

          git_panel = {
            dock = "left";
          };

          agent = {
            dock = "right";
            sidebar_side = "right";
            use_modifier_to_send = false;
            default_profile = "write";
            play_sound_when_agent_done = "always";
            inline_assistant_model = {
              provider = "copilot_chat";
              model = "claude-sonnet-4.6";
            };
            tool_permissions = {
              default = "allow";
            };
            default_model = {
              provider = "copilot_chat";
              model = "claude-opus-4.6";
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
            dock = "left";
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
            bash-language-server = lib.mkIf (!pkgs.stdenv.isDarwin) {
              binary = {
                path = "${unstablePkgs.bash-language-server}/bin/bash-language-server";
                arguments = [ "start" ];
              };
            };
            nixd = lib.mkIf (!pkgs.stdenv.isDarwin) {
              binary = {
                path = "${unstablePkgs.nixd}/bin/nixd";
              };
            };
            groovy = lib.mkIf (!pkgs.stdenv.isDarwin) {
              binary = {
                path = "${unstablePkgs.groovy-language-server}/bin/groovy-language-server";
              };
            };
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
              settings = {
                buffer_font_size = 14;
                ui_font_size = 14;
              };
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
              settings = {
                buffer_font_size = 20;
                ui_font_size = 18;
              };
            };
          };

          agent_servers = {
            codex-nix = lib.mkMerge [
              {
                type = "custom";
                default_model = "gpt-5.3-codex";
                default_config_options = {
                  mode = "full-access";
                  reasoning_effort = "high";
                };
              }
              (lib.mkIf (!pkgs.stdenv.isDarwin) {
                command = "${unstablePkgs.codex-acp}/bin/codex-acp";
              })
            ];

            copilot = lib.mkMerge [
              {
                type = "custom";
              }
              (lib.mkIf (!pkgs.stdenv.isDarwin) {
                command = "${unstablePkgs.github-copilot-cli}/bin/copilot";
                default_model = "claude-sonnet-4.6";
                args = [
                  "--acp"
                  "--stdio"
                  "--allow-all-tools"
                  "--allow-all-urls"
                ];
              })
            ];
          };
        }
      ];

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
          context = "Pane";
          bindings = {
            "alt-shift-l" = "pane::ActivateNextItem";
            "alt-shift-h" = "pane::ActivatePreviousItem";
          };
        }
        {
          context = "vim_mode == normal || (Pane && !Editor && !Terminal)";
          bindings = {
            "space w" = "pane::CloseActiveItem";
            "space v" = "pane::SplitRight";
            "space g" = "git_panel::ToggleFocus";
            "space h" = "workspace::ActivateNextPane";
            "space l" = "workspace::ActivatePreviousPane";
          };
        }
        {
          context = "Dock";
          bindings = {
            "alt-e" = "editor::ToggleFocus";
          };
        }
        {
          context = "Editor";
          bindings = {
            "alt-`" = "terminal_panel::ToggleFocus";
          };
        }
        {
          context = "Workspace && !Editor";
          bindings = {
            "alt-`" = "editor::ToggleFocus";
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
          context = "(vim_mode == normal && !Terminal) || (GitPanel && vim_mode == normal)";
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
