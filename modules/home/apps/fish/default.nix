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
      ];
    };
  };
}
