{
  pkgs,
  config,
  userConfig,
  ...
}:
{
  imports = [
    #inputs.sops-nix.homeManagerModules.sops
    (import ./applications/git.nix {
      inherit pkgs config;
    })
  ];

  # sops = {
  #   age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  #   defaultSopsFile = "${inputs.dot-secrets}/secrets.yaml";
  #   secrets = {
  #     "me/key".path = "${config.home.homeDirectory}/.ssh/id_me";
  #     "me/pub".path = "${config.home.homeDirectory}/.ssh/id_me.pub";
  #     "me/config".path = "${config.home.homeDirectory}/.config/git/include_me";
  #   };
  # };

  xdg.enable = true;

  # Per-directory XDG config entries for dotfiles
  xdg.configFile."btop".source = ../dotfiles/btop;
  xdg.configFile."wezterm".source = ../dotfiles/wezterm;

  home.username = userConfig.username;
  home.stateVersion = "25.05";
  home.packages = with pkgs; [
    age
    btop
    dust
    fd
    fzf
    gh
    lsd
    micro
    sd
    sops
    tabiew
    yazi
    wezterm
  ];

  programs = {
    ripgrep.enable = true;
    home-manager.enable = true;

    fish = {
      enable = true;
      shellInit = ''
        set -g fish_greeting
        set -x XDG_CONFIG_HOME $HOME/.config

        alias vcd "cd"
        alias vcat "cat"
        alias cat "bat"
        alias ls "lsd"
        alias tree "lsd --tree"
        alias gp "git pull -r --autostash && git submodule update -r"
        alias gd "git diff"
        alias gs "git status"
        alias zed "zeditor"
      '';
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    atuin = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        auto_sync = false;
        update_check = false;
        filter_mode = "host";
        filter_mode_shell_up_key_binding = "session";
        prefers_reduced_motion = true;
        enter_accept = true;
        inline_height = 15;
        history_format = "{command}\t{duration}";
      };
    };

    bat = {
      enable = true;
      config = {
        theme = "Visual Studio Dark+";
      };
    };

    starship = {
      enable = true;
      settings = {
        add_newline = false;
        palette = "default";

        format = ''[╭](fg:separator)$status$hostname$directory$cmd_duration$line_break[╰](fg:separator)$character'';

        palettes.default = {
          prompt_ok = "#c3e88d";
          prompt_err = "#ff757f";
          icon = "#161514";
          separator = "#737aa2";
          background = "#414868";
          host = "#7dcfff";
          directory = "#7aa83e";
          duration = "#ffc777";
          status = "#c53b53";
        };

        character = {
          success_symbol = "[❯](fg:prompt_ok)";
          error_symbol = "[❯](fg:prompt_err)";
        };

        directory = {
          format = "[─](fg:separator)[](fg:directory)[](fg:icon bg:directory)[](fg:directory bg:background)[ $path](bg:background)[](fg:background)";
          truncate_to_repo = false;
          truncation_length = 0;
        };

        status = {
          format = "[─](fg:separator)[](fg:status)[](fg:icon bg:status)[](fg:status bg:background)[ $status](bg:background)[](fg:background)";
          pipestatus = true;
          pipestatus_separator = "-";
          pipestatus_segment_format = "$status";
          pipestatus_format = ''[─](fg:separator)[](fg:status)[\\uf658](fg:icon bg:status)[](fg:status bg:background)[ $pipestatus](bg:background)[](fg:background)'';
          disabled = false;
        };

        cmd_duration = {
          format = "[─](fg:separator)[](fg:duration)[󱐋](fg:icon bg:duration)[](fg:duration bg:background)[ $duration](bg:background)[](fg:background)";
          min_time = 1000;
        };

        hostname = {
          ssh_only = true;
          format = "[─](fg:separator)[](fg:host)[󰍹](fg:icon bg:host)[](fg:host bg:background)[ $hostname](bg:background)[](fg:background)";
          disabled = false;
        };

        time = {
          format = "[](fg:duration)[󰥔](fg:icon bg:duration)[](fg:duration bg:background)[ $time](bg:background)[](fg:background)";
          disabled = false;
        };
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          extraOptions = {
            AddKeysToAgent = "yes";
            Compression = "yes";
            ControlMaster = "auto";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "10m";
            ServerAliveInterval = "60";
          };
        };
        mini = {
          hostname = "mini.local";
          user = "dirk";
          extraOptions = {
            requestTTY = "true";
          };
        };
        inky = {
          hostname = "inky.local";
          user = "dirk";
        };
        vito = {
          hostname = "192.168.1.43";
          user = "Vito\\vdboerd";
        };
        odroid = {
          hostname = "odroid.local";
          user = "dirk";
        };
        nas = {
          hostname = "nas.local";
          user = "dirk";
          port = 6987;
        };
        cluster = {
          hostname = "develop.marvin.vito.local";
          user = "vdboerd";
          proxyCommand = "nc -x localhost:1080 -X 5 %h %p";
          extraOptions = {
            remoteCommand = "fish";
            requestTTY = "true";
          };
        };
        clusterfs = {
          hostname = "develop.marvin.vito.local";
          proxyCommand = "nc -x localhost:1080 -X 5 %h %p";
          user = "vdboerd";
        };
      };
    };

    zed-editor = {
      enable = true;
      extensions = [ "nix" ];
      extraPackages = with pkgs; [
        nil
        nixd
      ];
    };
  };
}
