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
      set -x XDG_CONFIG_HOME $HOME/.config
    '';

    # interactiveShellInit = ''
    #   zellij_tab_cmd
    #   zellij_tab_dir

    #   if status is-interactive
    #     eval (zellij setup --generate-auto-start fish | string collect)
    #   end

    #   set fish_greeting # Disable greeting

    #   abbr -a -- .. "cd .."
    #   abbr -a -- ... "cd ../.."
    #   abbr -a -- .... "cd ../../.."
    #   abbr -a -- ..... "cd ../../../.."
    #   abbr -a -- - "cd -"
    # '';

    shellAbbrs = {
      cat = "bat";
      cd = "z";
      gd = "git diff";
      gp = "git pull -r --autostash && git submodule update -r";
      gs = "git status";
      k = "kubectl";
      ll = "ls -la";
      ls = "lsd";
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
