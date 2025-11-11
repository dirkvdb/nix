{ pkgs, config, ... }:
let
  inherit (config.local) user;
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
        nrs = if pkgs.stdenv.isDarwin then "nh darwin switch ~/nix" else "nh os switch ~/nix";
        tree = "lsd --tree";
        zed = if pkgs.stdenv.isDarwin then "zed" else "zeditor";
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
