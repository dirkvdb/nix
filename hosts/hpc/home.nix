{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  userName = "vdboerd";
  userHome = "/home/${userName}";
in
{
  imports = [
    inputs.stylix.homeModules.stylix
    inputs.zen-browser.homeModules.default
    inputs.nvf.homeManagerModules.default
    ../../modules/common/options
    ../../modules/common/theme
    ../../modules/home/import.nix
  ];

  config = {
    home = {
      username = userName;
      homeDirectory = userHome;
      stateVersion = "25.05";
    };

    # Enable XDG but disable mime (which can pull in cursor/desktop deps)
    xdg = {
      enable = true;
      mimeApps.enable = lib.mkForce false;
      systemDirs.data = lib.mkForce [ ];
    };

    # Stylix theme - enabled for terminal/CLI only, no desktop features
    stylix = {
      enable = true;
      autoEnable = false;
      base16Scheme = config.local.theme.base16Scheme;
      # Only enable terminal/CLI targets (no GUI/desktop)
      targets.bat.enable = true;
      targets.btop.enable = true;
      targets.fish.enable = true;
    };

    # Disable dconf completely (requires dbus which isn't available in Docker)
    dconf.enable = false;

    # Configure using the local options
    local = {
      user = {
        enable = true;
        name = userName;
        homeDir = userHome;
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      # Disable desktop to prevent cursor/icon themes from being installed
      desktop.enable = false;
      headless = true;

      # Use everforest theme (only terminal/CLI styling, no GUI)
      theme.preset = "everforest";

      home-manager.standalone = true;
    };
  };
}
