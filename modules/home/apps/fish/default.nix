{
  pkgs,
  config,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  sopsEnabled = config.local.apps.sops.enable or false;
  isStandalone = config.local.home-manager.standalone or false;
  configName = config.local.home-manager.configName or user.name;
  mkUserHome = mkHome user.name;
in
{
  config = mkUserHome {

    home.packages =
      with pkgs;
      [
        fzf
        fishPlugins.fzf
      ]
      ++ lib.optionals isStandalone [
        # In standalone home-manager, fish needs to be explicitly installed
        pkgs.fish
      ];

    programs.man.generateCaches = false;
    programs.fish = {
      enable = true;

      shellInit = ''
        set -g fish_greeting

        ${lib.optionalString isStandalone ''
          # In standalone home-manager, ensure ~/.nix-profile/bin is in PATH
          fish_add_path --path --prepend ~/.nix-profile/bin
        ''}

        ${lib.optionalString sopsEnabled ''
          set -gx GITHUB_TOKEN (cat ${config.sops.secrets.github_token.path} | string trim)
        ''}

        # Enable vi mode
        fish_vi_key_bindings

        # Atuin vi mode bindings
        bind -M default k _atuin_search
        bind -M default j down-or-search
      '';

      shellAbbrs = {
        cat = "bat";
        gd = "git diff";
        gp = "git pull -r --autostash && git submodule update -r";
        gs = "git status";
        k = "kubectl";
        ll = "lsd -la";
        ls = "lsd";
        lg = "lazygit";
        dv = "zeditor .";
        man = "batman";
        nrs =
          if isStandalone then
            "nix run home-manager/release-25.11 -- switch -b backup --flake ~/nix#${configName}"
          else if pkgs.stdenv.isDarwin then
            "nh darwin switch ~/nix"
          else
            "nh os switch -j2 ~/nix && nixcfg-reload";
        update =
          if isStandalone then
            "git -C ~/nix pull -r --autostash && nrs"
          else if pkgs.stdenv.isDarwin then
            "nh darwin switch -j2 --update --commit-lock-file ~/nix"
          else
            "git -C ~/nix pull -r --autostash && nh os switch -j2 --update --commit-lock-file ~/nix";
        tree = "lsd --tree";
        zed = lib.mkIf (config.local.desktop.enable or false) "zeditor";
        nodenv = "direnv exec / fish --no-config";
      };

      interactiveShellInit = lib.optionalString config.local.system.dev.enable ''
        # devenv native auto-activation (v2.1+)
        devenv hook fish | source
      '';

      plugins = [
        {
          name = "fzf";
          src = pkgs.fishPlugins.fzf.src;
        }
      ];
    };
  };
}
