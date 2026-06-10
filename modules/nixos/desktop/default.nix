{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.local.desktop;
  user = config.local.user;
in
{
  options.local.desktop.mimeTypes = {
    nautilus = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "inode/directory"
      ];
      description = "MIME types for which Nautilus is the default handler.";
    };

    fileRoller = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "application/zip"
        "application/gzip"
        "application/x-tar"
        "application/x-compressed-tar"
        "application/x-7z-compressed"
        "application/x-rar-compressed"
        "application/x-bzip2-compressed-tar"
        "application/x-xz-compressed-tar"
      ];
      description = "MIME types for which File Roller is the default handler.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable polkit for privilege escalation
    security.polkit.enable = true;

    fonts.fontconfig = {
      enable = true;

      antialias = true;

      subpixel = {
        rgba = "none";
        lcdfilter = "none";
      };

      hinting = {
        enable = true;
        style = "slight"; # or "none" if you prefer shape fidelity
      };
    };

    xdg.terminal-exec = {
      enable = true;
      settings = {
        default = [ "com.mitchellh.ghostty.desktop" ];
      };
    };

    qt = {
      enable = true;
      #platformTheme = "gtk2";
      #style = "adwaita-dark";
    };

    environment.systemPackages = with pkgs; [
      glib # for gsettings to work
      eyedropper
      font-manager
      gsettings-qt
      nautilus
      ffmpegthumbnailer
      file-roller # archive manager
      notify-desktop # cmd for sending notifications
      xdg-terminal-exec
    ];

    services = {
      gvfs.enable = true; # Nautilus
      devmon.enable = true; # automatic device mounting daemon
      udisks2.enable = true; # DBus service that allows applications to query and manipulate storage devices
      # upower.enable = true; # D-Bus service for power management.
      # power-profiles-daemon.enable = true;

      gnome = {
        sushi.enable = true; # a quick previewer for nautilus
      };
    };

    home-manager.users.${user.name} = {
      xdg.mimeApps.defaultApplications =
        lib.genAttrs cfg.mimeTypes.nautilus (_: "org.gnome.Nautilus.desktop")
        // lib.genAttrs cfg.mimeTypes.fileRoller (_: "org.gnome.FileRoller.desktop");
    };
  };
}
