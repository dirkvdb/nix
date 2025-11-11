{
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/darwin/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    # Fix GID mismatch for nixbld group: remove on next clean install
    ids.gids.nixbld = 350;
    system.stateVersion = 6;

    local = {
      user = {
        enable = true;
        name = "dirk";
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      theme.preset = "everforest";

      apps = {
        raycast.enable = true;
        karabiner.enable = true;
        bitwarden.enable = false;
        localsend.enable = true;
      };

      tools = {
        homebrew.enable = true;
      };

      system = {
        defaults.enable = true;

        network = {
          hostname = "macbook-pro";
        };

        nix = {
          unfree.enable = true;
          nh.enable = true;
          flakes.enable = true;
        };

        utils = {
          dev = true;
          sysadmin = true;
        };
      };

      home-manager = {
        skhd.enable = true;
        ghostty.enable = true;

        keepassxc = {
          enable = true;

          databasePaths = [
            "/Users/dirk/Secrets/Desktop.kdbx"
          ];
          keyfilePath = "/Users/dirk/.local/share/desktop.key";
        };
      };
    };

    # Create /etc/zshrc that loads the nix-darwin environment.
    programs = {
      gnupg.agent.enable = true;
      zsh.enable = true;
    };

    fonts.packages = with pkgs; [
      monaspace
      cascadia-code
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.caskaydia-mono
    ];

    homebrew = {
      masApps = {
        Amphetalocal = 937984704;
        Pages = 409201541;
        Numbers = 409203825;
      };

      casks = [
        # Not available for macOS in nixpkgs:
        "balenaetcher"
        "dropbox"
        # bruno
        "ghostty"
        "vivaldi"
        "fork"
        "microsoft-teams"
        "microsoft-outlook"
        "microsoft-excel"
        "microsoft-auto-update"
        "visual-studio-code"
        "orbstack"
        #"qgis"
        # autodesk-fusion
        "raycast"
        "spotify"
        "passepartout"
        "whatsapp"
        "zed"
        "zen"
      ];
    };
  };
}
