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
  mkUserHome = mkHome user.name;
in
{
  config = mkUserHome {

    home.packages = with pkgs; [
      fzf
      fishPlugins.fzf
    ];

    programs.fish = {
      enable = true;

      shellInit = ''
        set -g fish_greeting

        ${lib.optionalString sopsEnabled ''
          set -gx OPENAI_API_KEY (cat ${config.sops.secrets.openai_api_key.path} | string trim)
          set -gx GITHUB_TOKEN (cat ${config.sops.secrets.github_token.path} | string trim)
        ''}

        bind \cx beginning-of-line
        bind \cb backward-word
        bind \cf forward-word
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
        man = "batman";
        nrs =
          if pkgs.stdenv.isDarwin then
            "nh darwin switch ~/nix"
          else
            "nh os switch -j2 ~/nix && nixcfg-reload";
        update =
          if pkgs.stdenv.isDarwin then
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
