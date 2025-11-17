{ pkgs, config, ... }:
let
  inherit (config.local) user;
  isWsl = config.wsl.enable or false;
in
{
  home-manager.users.${user.name} = {

    home.packages = with pkgs; [
      fzf
      fishPlugins.fzf
    ];

    programs.fish = {
      enable = true;

      shellInit = ''
        set -g fish_greeting

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
          else if isWsl then
            "nh os switch -H wsl"
          else
            "nh os switch ~/nix && nixcfg-reload";
        update =
          if pkgs.stdenv.isDarwin then
            "nh darwin switch --update --commit-lock-file ~/nix"
          else if isWsl then
            "nh os switch --update --commit-lock-file -H wsl"
          else
            "nh os switch --update --commit-lock-file ~/nix";
        tree = "lsd --tree";
        zed = if pkgs.stdenv.isDarwin || isWsl then "zed" else "zeditor";
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
