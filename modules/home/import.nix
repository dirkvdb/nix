{
  pkgs,
  lib,
  config,
  mkHome,
  unstablePkgs,
  ...
}:
let
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless or false;
  isStandalone = config.local.home-manager.standalone or false;

  # Credit: @infinisil
  # https://github.com/Infinisil/system/blob/df9232c4b6cec57874e531c350157c37863b91a0/config/new-modules/default.nix

  getDir =
    dir:
    lib.mapAttrs (file: type: if type == "directory" then getDir "${dir}/${file}" else type) (
      builtins.readDir dir
    );

  files =
    dir:
    lib.collect lib.isString (
      lib.mapAttrsRecursive (path: type: lib.concatStringsSep "/" path) (getDir dir)
    );

  getDefaultNix =
    dir:
    map (file: ./. + "/${file}") (builtins.filter (file: baseNameOf file == "default.nix") (files dir));

in
{
  options.local.home-manager = {
    standalone = lib.mkEnableOption "Use home-manager in standalone mode";

    configName = lib.mkOption {
      type = lib.types.str;
      default = user.name;
      description = "Name of the home-manager flake configuration (used in standalone mode)";
      example = "hpc";
    };
  };

  imports = getDefaultNix ./.;

  config = mkUserHome {
    xdg.enable = true;
    xdg.mimeApps.enable = !pkgs.stdenv.isDarwin;

    # Per-directory XDG config entries for dotfiles
    xdg.configFile."btop".source = ./dotfiles/btop;
    xdg.configFile."wezterm".source = ./dotfiles/wezterm;

    xdg.configFile."sublime-merge/Packages/User".source = ./dotfiles/sublime-merge/Packages/User;

    # Add ~/.local/bin to PATH
    home.sessionPath = [
      "${user.homeDir}/.local/bin"
    ];

    home.sessionVariables = {
      BROWSER = "zen";
    };

    home.packages =
      (with pkgs; [
        age
        autossh
        dust
        fd
        fzf
        gh
        lsd
        micro
        rsync
        sd
        tabiew

      ])
      ++ lib.optionals (!pkgs.stdenv.isDarwin) (
        with unstablePkgs;
        [
          ec
        ]
      )
      ++ lib.optionals isStandalone (
        with pkgs;
        [
          devenv
          just
          lazygit
          serie
          binsider
          nixd
          unstablePkgs.pixi
        ]
      )

      ++ lib.optionals (!isHeadless && !pkgs.stdenv.isDarwin) (
        with pkgs;
        [
          sqlitebrowser
          wezterm
          (writeShellScriptBin "sublime_merge" ''
            exec env \
              GDK_BACKEND=wayland \
              ${sublime-merge}/bin/sublime_merge "$@"
          '')
        ]
      );

    programs = {
      git.enable = true;
      ripgrep.enable = true;
      home-manager.enable = true;

      zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [ "--cmd=cd" ];
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
          inline_height = 20;
          history_format = "{command}";
          columns = [
            "duration"
            "command"
          ];
          keymap_mode = "vim-normal";
        };
      };

      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batman
        ];
      };

      yazi = {
        enable = true;
        plugins = {
          git = pkgs.yaziPlugins.git;
          githead = pkgs.yaziPlugins.githead;
        };
        initLua = ''
          require("git"):setup {
            order = 1500,
          }
          require("githead"):setup({
            branch_prefix = "on",
            branch_symbol = " ",
            branch_borders = "()",
          })
        '';
        settings = {
          mgr = {
            linemode = "none";
          };
          plugin = {
            prepend_fetchers = [
              {
                id = "git";
                url = "*";
                run = "git";
                prio = "normal";
                group = "git";
              }
              {
                id = "git";
                url = "*/";
                run = "git";
                prio = "normal";
                group = "git";
              }
            ];
          };
        };
      };
    };
  };

}
