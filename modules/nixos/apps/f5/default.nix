{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.local.apps.f5;
  user = config.local.user;

  # F5 VPN client package built from deb
  f5vpn = pkgs.stdenv.mkDerivation {
    pname = "f5vpn";
    version = "7260.2024.0718.1";

    src = pkgs.fetchurl {
      url =
        if pkgs.stdenv.hostPlatform.isAarch64 then
          "https://byod.vito.be/public/download/linux_f5vpn.aarch64.deb"
        else
          "https://byod.vito.be/public/download/linux_f5vpn.x86_64.deb";
      hash =
        if pkgs.stdenv.hostPlatform.isAarch64 then
          "sha256-RFfJSsb9r5+uqPMuP4enLZd/i9q4WfBb8i0uf5e7Zd4="
        else
          "sha256-W9mDSeW4PSfqCDlUPYg84vjZ5Uxc7mciC4uip+xT6g0=";
    };

    nativeBuildInputs = with pkgs; [
      dpkg
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = with pkgs; [
      glib
      gtk3
      webkitgtk_4_1
      libsoup_3
      openssl
      zlib
      stdenv.cc.cc.lib
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXtst
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilrenderutil
      xorg.xcbutilwm
      xorg.xcbutilcursor
      xorg.libxshmfence
      xorg.libxkbfile
      libxkbcommon
      systemd
      # Qt6 WebEngine dependencies
      nss
      nspr
      alsa-lib
      snappy
      minizip
    ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      runHook preInstall

      # Install the F5 VPN files
      mkdir -p $out/opt/f5/vpn
      cp -r opt/f5/vpn/* $out/opt/f5/vpn/

      # Create bin directory with wrapped executables
      mkdir -p $out/bin

      # Wrap f5vpn with correct Qt environment
      makeWrapper $out/opt/f5/vpn/f5vpn $out/bin/f5vpn \
        --set QT_PLUGIN_PATH "$out/opt/f5/vpn/plugins" \
        --set QT_QPA_PLATFORM "xcb" \
        --set QT_QPA_PLATFORM_PLUGIN_PATH "$out/opt/f5/vpn/platforms" \
        --set QT_QPA_FONTDIR "${pkgs.xorg.fontmiscmisc}/lib/X11/fonts/misc" \
        --set QT_SCALE_FACTOR "2.0" \
        --unset QT_STYLE_OVERRIDE \
        --prefix LD_LIBRARY_PATH : "$out/opt/f5/vpn/lib"

      # Wrap svpn as well
      makeWrapper $out/opt/f5/vpn/svpn $out/bin/svpn \
        --prefix LD_LIBRARY_PATH : "$out/opt/f5/vpn/lib"

      # Install desktop file with corrected Exec path
      mkdir -p $out/share/applications
      substitute $out/opt/f5/vpn/com.f5.f5vpn.desktop $out/share/applications/com.f5.f5vpn.desktop \
        --replace-fail "/opt/f5/vpn/f5vpn_launch_helper.sh" "$out/bin/f5vpn"

      # Install D-Bus service file with corrected Exec path
      mkdir -p $out/share/dbus-1/services
      substitute $out/opt/f5/vpn/com.f5.f5vpn.service $out/share/dbus-1/services/com.f5.f5vpn.service \
        --replace-fail "/opt/f5/vpn/f5vpn_launch_helper.sh" "$out/bin/f5vpn"

      # Install icons
      mkdir -p $out/share/icons/hicolor/48x48/apps
      mkdir -p $out/share/icons/hicolor/128x128/apps
      cp $out/opt/f5/vpn/logos/48x48.png $out/share/icons/hicolor/48x48/apps/f5vpn.png
      cp $out/opt/f5/vpn/logos/128x128.png $out/share/icons/hicolor/128x128/apps/f5vpn.png

      runHook postInstall
    '';

    meta = with lib; {
      description = "F5 BIG-IP Edge Client VPN";
      homepage = "https://www.f5.com/";
      license = licenses.unfree;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maintainers = [ ];
    };
  };

  # FHS environment for running F5 VPN (some components may need this)
  f5vpn-fhs = pkgs.buildFHSEnv {
    name = "f5vpn-fhs";
    targetPkgs =
      pkgs: with pkgs; [
        f5vpn
        glib
        gtk3
        webkitgtk_4_1
        libsoup_3
        openssl
        zlib
        stdenv.cc.cc.lib
        xorg.libX11
        xorg.libXext
        xorg.libXrender
        xorg.libXtst
        systemd
        icu
        nss
        nspr
        cups
        dbus
        at-spi2-atk
        libdrm
        mesa
        libxkbcommon
        pango
        cairo
        alsa-lib
        expat
      ];
    runScript = "f5vpn";
    meta = {
      description = "F5 VPN client in FHS environment";
    };
  };
in
{
  options.local.apps.f5 = {
    enable = lib.mkEnableOption "F5 BIG-IP Edge Client VPN";

    useFHSEnv = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to use an FHS environment wrapper.
        Enable this if you encounter issues with the directly patched binary.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      f5vpn # Always install for desktop file and icons
    ]
    ++ lib.optionals cfg.useFHSEnv [
      f5vpn-fhs
    ];

    # Register f5-vpn:// URL scheme handler in home-manager
    home-manager.users.${user.name} = {
      xdg.mimeApps.associations.added = {
        "x-scheme-handler/f5-vpn" = "com.f5.f5vpn.desktop";
      };
      xdg.mimeApps.defaultApplications = {
        "x-scheme-handler/f5-vpn" = "com.f5.f5vpn.desktop";
      };
    };

    # Create symlink for svpn at the hardcoded path F5 VPN expects
    systemd.tmpfiles.rules = [
      "d /opt/f5/vpn 0755 root root -"
      "L+ /opt/f5/vpn/svpn - - - - ${f5vpn}/bin/svpn"
    ];

    # F5 VPN requires tun device
    boot.kernelModules = [ "tun" ];

    # Allow the VPN to create network interfaces
    networking.firewall.checkReversePath = "loose";

    # Systemd service for F5 VPN daemon (if needed)
    systemd.services.f5vpn = {
      description = "F5 VPN Service";
      wantedBy = [ ]; # Don't start automatically, user can enable if needed
      serviceConfig = {
        Type = "simple";
        ExecStart = "${if cfg.useFHSEnv then f5vpn-fhs else f5vpn}/bin/f5vpn";
        Restart = "on-failure";
      };
    };
  };
}
