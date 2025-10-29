{ pkgs, ... }:
{
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
      ll = "ls -la";
      ls = "lsd";
      man = "batman";
      nrs =
        if pkgs.stdenv.isDarwin then
          "sudo darwin-rebuild switch --flake ~/.config/nix#MacBook-Pro"
        else
          "sudo nixos-rebuild switch --flake ~/nix";
      tree = "lsd --tree";
      zed = "zeditor";
    };

    plugins = [
      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf.src;
      }
    ];
  };
}
