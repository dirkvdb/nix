{ writeShellScriptBin, dbus }:
writeShellScriptBin "nixcfg-wait-for-tray" ''
  # Wait until the StatusNotifierWatcher is registered on D-Bus,
  # which signals that the system tray is ready to accept icons.
  while ! ${dbus}/bin/dbus-send --session --dest=org.freedesktop.DBus \
        --type=method_call --print-reply \
        /org/freedesktop/DBus org.freedesktop.DBus.NameHasOwner \
        string:org.kde.StatusNotifierWatcher 2>/dev/null \
      | grep -q "boolean true"; do
    sleep 0.5
  done
''
