{ pkgs, ... }:
{
  environment = {
    variables.EDITOR = "micro";
    # variables.XDG_CONFIG_HOME = "${config.xdg.configHome}";

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    systemPackages = with pkgs; [
      home-manager
      bitwarden-cli
      raycast
      sqlitebrowser
    ];
  };

  services.aerospace = {
    enable = true;
    settings = pkgs.lib.importTOML ../../configs/aerospace.toml;
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      cleanup = "zap";
    };

    masApps = {
      Amphetamine = 937984704;
      Pages = 409201541;
      Numbers = 409203825;
    };

    taps = [
      "FelixKratz/formulae"
    ];

    brews = [
      "borders" # from tap: FelixKratz/formulae
    ];

    casks = [
      # Managed by nix: alt-tab-macos, iina, karabiner-elements, raycast, wezterm, zed-editor
      # Not available for macOS in nixpkgs:
      "ghostty"
      "vivaldi"
      "fork"
      "localsend"
      "microsoft-teams"
      "microsoft-outlook"
      "microsoft-excel"
      "orbstack"
      "raycast"
      "spotify"
      "whatsapp"
      "zen"

      # font-fira-code
      #                                 font-fira-code-nerd-font        qgis
      # autodesk-fusion                 font-fira-mono-nerd-font
      # balenaetcher                    font-lobster
      # bruno                                            stats
      # db-browser-for-sqlite
      # google-chrome
      # font-cascadia-code
      # font-cascadia-code-pl
      # font-caskaydia-mono-nerd-font
      # font-courgette
    ];
  };
}
