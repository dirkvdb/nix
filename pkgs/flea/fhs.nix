{
  buildFHSEnv,
  flea-unwrapped,
  gvfs,
  qt6,
  writeShellScript,
}:
# Flea expects Arch-style /usr paths, including inside its bwrap jails.
buildFHSEnv {
  pname = "flea";
  version = flea-unwrapped.version;
  targetPkgs = _: [ flea-unwrapped ] ++ flea-unwrapped.runtimeInputs;
  # D-Bus activation's temporary parent exits once the backend acquires its name.
  dieWithParent = false;
  runScript = writeShellScript "flea-launcher" ''
    case "''${1:-}" in
      --flea-portal)
        shift
        exec ${flea-unwrapped}/lib/flea/flea-portal "$@"
        ;;
      --flea-filemanager1)
        shift
        exec ${flea-unwrapped}/lib/flea/flea-filemanager1 "$@"
        ;;
      *)
        exec ${flea-unwrapped}/bin/flea "$@"
        ;;
    esac
  '';
  extraBuildCommands = ''
    mkdir -p $out/usr/bin $out/usr/lib64 $out/usr/share/omarchy
    ln -sfn ${qt6.qtdeclarative}/bin/qml $out/usr/bin/qml6
    ln -sfn ${gvfs}/libexec/gvfsd-fuse $out/usr/lib64/gvfsd-fuse
  '';
  extraPreBwrapCmds = ''
    # Keep the host's Stylix-selected icon theme visible inside the FHS root.
    ro_mounts+=(--ro-bind-try /run/current-system/sw/share/icons /.host-icons)
    ro_mounts+=(--ro-bind-try /usr/share/omarchy /.host-omarchy)
  '';
  extraBwrapArgs = [
    "--ro-bind-try"
    "/.host-icons"
    "/usr/share/icons"
    "--ro-bind-try"
    "/.host-omarchy"
    "/usr/share/omarchy"
  ];
  extraInstallCommands = ''
    mkdir -p $out/share
    ln -s ${flea-unwrapped}/share/applications $out/share/applications
    # D-Bus starts these outside the FHS root unless activation goes through the launcher.
    cp -r ${flea-unwrapped}/share/dbus-1 $out/share/dbus-1
    chmod -R u+w $out/share/dbus-1
    substituteInPlace $out/share/dbus-1/services/org.freedesktop.impl.portal.desktop.flea.service \
      --replace-fail '${flea-unwrapped}/lib/flea/flea-portal' "$out/bin/flea --flea-portal"
    substituteInPlace $out/share/dbus-1/services/com.thisisgm.flea.FileManager1.service \
      --replace-fail '${flea-unwrapped}/lib/flea/flea-filemanager1' "$out/bin/flea --flea-filemanager1"
    ln -s ${flea-unwrapped}/share/icons $out/share/icons
    ln -s ${flea-unwrapped}/share/xdg-desktop-portal $out/share/xdg-desktop-portal
  '';
  meta = flea-unwrapped.meta // {
    mainProgram = "flea";
  };
}
