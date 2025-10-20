{ pkgs, ... }:
{
  environment.variables.EDITOR = "micro";
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
      "Microsoft Excel" = 462058435;
    };

    # brews = [
    #   "curl" # no not install curl via nixpkgs, it's not working well on macOS!
    # ];

    casks = [
      # Managed by nix: alt-tab-macos, iina, karabiner-elements, raycast, wezterm, zed-editor
      # Not available for macOS in nixpkgs:
      "ghostty"
      "vivaldi"
      "karabiner-elements"
      "fork"
      "spotify"
      "whatsapp"
      "zen"

      # font-fira-code                  postman
      #                                 font-fira-code-nerd-font        qgis
      # autodesk-fusion                 font-fira-mono-nerd-font
      # balenaetcher                    font-lobster
      # bruno                           font-noto-emoji                 stats
      # db-browser-for-sqlite                                       vivaldi
      # firefox                         google-chrome                   whatsapp
      # font-cascadia-code              iina
      # font-cascadia-code-pl
      # font-caskaydia-mono-nerd-font   microsoft-auto-update
      # font-courgette                  orbstack
    ];
  };
}
