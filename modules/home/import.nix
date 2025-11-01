{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.local) user;

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
  imports = getDefaultNix ./.;

  home-manager.users.${user.name} = {
    xdg.enable = true;

    # Per-directory XDG config entries for dotfiles
    xdg.configFile."btop".source = ./dotfiles/btop;
    xdg.configFile."ghostty".source = ./dotfiles/ghostty;
    xdg.configFile."wezterm".source = ./dotfiles/wezterm;

    # Add ~/.local/bin to PATH
    home.sessionPath = [
      "${user.homeDir}/.local/bin"
    ];

    home.packages = with pkgs; [
      age
      autossh
      #btop
      bitwarden-cli
      dust
      fd
      fzf
      gh
      lsd
      micro
      rsync
      sd
      sqlitebrowser
      tabiew
      yazi
      wezterm
    ];

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
        };
      };

      bat = {
        enable = true;
        config = {
          theme = "Visual Studio Dark+";
        };
        extraPackages = with pkgs.bat-extras; [
          batman
        ];
      };
    };
  };

}
