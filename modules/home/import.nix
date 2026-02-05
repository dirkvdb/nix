{
  pkgs,
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless or false;

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
    builtins.map (file: ./. + "/${file}") (
      builtins.filter (file: builtins.baseNameOf file == "default.nix") (files dir)
    );

in
{
  options.local.home-manager.standalone = lib.mkEnableOption "Use home-manager in standalone mode";

  imports = getDefaultNix ./.;

  config = mkUserHome {
    xdg.enable = true;

    # Set Zen as the default browser
    xdg.mimeApps = {
      enable = !pkgs.stdenv.isDarwin;
      defaultApplications = {
        "text/html" = "zen-beta.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "x-scheme-handler/about" = "zen-beta.desktop";
        "x-scheme-handler/unknown" = "zen-beta.desktop";
      };
    };

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
        yazi
      ])
      ++ lib.optionals (!isHeadless) (
        with pkgs;
        [
          sqlitebrowser
          wezterm
        ]
      );

    programs = {
      git.enable = true;
      ripgrep.enable = true;
      home-manager.enable = true;

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
          keymap_mode = "vim-normal";
        };
      };

      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batman
        ];
      };
    };
  };

}
