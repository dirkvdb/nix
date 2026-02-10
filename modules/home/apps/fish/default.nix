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

    programs.fish = {
      enable = true;

      shellInit = ''
        set -g fish_greeting

        ${lib.optionalString isStandalone ''
          # In standalone home-manager, ensure ~/.nix-profile/bin is in PATH
          fish_add_path --path --prepend ~/.nix-profile/bin
        ''}

        ${lib.optionalString sopsEnabled ''
          set -gx OPENAI_API_KEY (cat ${config.sops.secrets.openai_api_key.path} | string trim)
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
        cd = "z";
        gd = "git diff";
        gp = "git pull -r --autostash && git submodule update -r";
        gs = "git status";
        k = "kubectl";
        ll = "lsd -la";
        ls = "lsd";
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

      plugins = [
        {
          name = "fzf";
          src = pkgs.fishPlugins.fzf.src;
        }
        # {
        #   # https://github.com/direnv/direnv/issues/443
        #   # INFO: Using this to get shell completion for programs added to the path through nix+direnv.
        #   # Issue to upstream into direnv:Add commentMore actions
        #   #
        #   name = "completion-sync";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "iynaix";
        #     repo = "fish-completion-sync";
        #     rev = "4f058ad2986727a5f510e757bc82cbbfca4596f0";
        #     sha256 = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
        #   };
        # }
      ];
    };
  };
}
