{ pkgs, ... }:
{
  environment = {
    variables.EDITOR = "micro";
    # variables.XDG_CONFIG_HOME = "${config.xdg.configHome}";

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    systemPackages = with pkgs; [
      home-manager
      raycast
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
      # Not available for macOS in nixpkgs:
      # balenaetcher
      # bruno
      "ghostty"
      "vivaldi"
      "fork"
      "localsend"
      "microsoft-teams"
      "microsoft-outlook"
      "microsoft-excel"
      "orbstack"
      #"qgis"
      # autodesk-fusion
      "raycast"
      "spotify"
      "whatsapp"
      "zen"
    ];
  };
}
