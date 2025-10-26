{
  config,
  pkgs,
  userConfig,
  ...
}:
{
  imports = [
    #inputs.sops-nix.homeManagerModules.sops
    ./applications/fish.nix
    ./applications/git.nix
    ./applications/starship.nix
    ./applications/ssh.nix
  ];

  # sops = {
  #   age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  #   defaultSopsFile = "${inputs.dot-secrets}/secrets.yaml";
  #   secrets = {
  #     "me/key".path = "${config.home.homeDirectory}/.ssh/id_me";
  #     "me/pub".path = "${config.home.homeDirectory}/.ssh/id_me.pub";
  #     "me/config".path = "${config.home.homeDirectory}/.config/git/include_me";
  #   };
  # };

  xdg.enable = true;

  # Per-directory XDG config entries for dotfiles
  xdg.configFile."btop".source = ./dotfiles/btop;
  xdg.configFile."wezterm".source = ./dotfiles/wezterm;
  xdg.dataFile."wallpaper.jpg".source = ./wallpapers/everforest.jpg;

  home.username = userConfig.username;
  home.stateVersion = "25.05";

  # Add ~/.local/bin to PATH
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  home.packages = with pkgs; [
    age
    autossh
    btop
    bitwarden-cli
    bitwarden-desktop
    dust
    fd
    fzf
    gh
    lsd
    micro
    rsync
    sd
    sqlitebrowser
    sops
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
    };

    zed-editor = {
      enable = true;
      extensions = [ "nix" ];
      extraPackages = with pkgs; [
        nil
        nixd
      ];
    };
  };
}
