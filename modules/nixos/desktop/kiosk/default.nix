{
  lib,
  pkgs,
  unstablePkgs,
  config,
  ...
}:
let
  cfg = config.local.desktop.kiosk;

  # A minimal cursor theme whose only cursor is a 1×1 fully transparent
  # image. Used when hideCursor = true to prevent cage from showing a
  # stray cursor on pointer-less kiosk displays.
  #
  # The Xcursor binary format is tiny and well-defined, so we write it
  # directly rather than pulling in Python + xcursorgen. Layout:
  #   - 16-byte file header: magic "Xcur", header size (16), version
  #     (0x00010000), ntoc = 1
  #   - 12-byte table-of-contents entry: type = 0xfffd0002 (image),
  #     subtype = 1 (nominal size), position = 28
  #   - 36-byte image chunk header: header size (36), type, subtype,
  #     version (1), width (1), height (1), xhot (0), yhot (0), delay (0)
  #   -  4 bytes of ARGB pixel data, all zero (fully transparent)
  transparentCursorTheme = pkgs.runCommand "transparent-cursor-theme" { } ''
    mkdir -p "$out/share/icons/transparent/cursors"

    # Bytes for the Xcursor file (little-endian throughout).
    {
      printf 'Xcur'                              # magic
      printf '\x10\x00\x00\x00'                  # header size = 16
      printf '\x00\x00\x01\x00'                  # version = 0x00010000
      printf '\x01\x00\x00\x00'                  # ntoc = 1
      # TOC entry
      printf '\x02\x00\xfd\xff'                  # type = 0xfffd0002 (image)
      printf '\x01\x00\x00\x00'                  # subtype = 1 (nominal size)
      printf '\x1c\x00\x00\x00'                  # position = 28
      # Image chunk
      printf '\x24\x00\x00\x00'                  # header size = 36
      printf '\x02\x00\xfd\xff'                  # type
      printf '\x01\x00\x00\x00'                  # subtype
      printf '\x01\x00\x00\x00'                  # version = 1
      printf '\x01\x00\x00\x00'                  # width = 1
      printf '\x01\x00\x00\x00'                  # height = 1
      printf '\x00\x00\x00\x00'                  # xhot = 0
      printf '\x00\x00\x00\x00'                  # yhot = 0
      printf '\x00\x00\x00\x00'                  # delay = 0
      printf '\x00\x00\x00\x00'                  # ARGB pixel (transparent)
    } > "$out/share/icons/transparent/cursors/default"

    # Alias every common cursor name to the same transparent cursor.
    cd "$out/share/icons/transparent/cursors"
    for name in left_ptr x_cursor pointer hand hand1 hand2 \
                watch wait progress move fleur grab grabbing \
                col-resize row-resize \
                n-resize s-resize e-resize w-resize \
                ne-resize nw-resize se-resize sw-resize \
                ns-resize ew-resize nwse-resize nesw-resize; do
      ln -s default "$name"
    done

    printf '[Icon Theme]\nName=Transparent\n' \
      > "$out/share/icons/transparent/index.theme"
  '';
in
{
  options.local.desktop.kiosk = {
    enable = lib.mkEnableOption "Enable kiosk desktop environment using cage";

    user = lib.mkOption {
      type = lib.types.str;
      default = config.local.user.name;
      description = "The user to run the kiosk session as.";
    };

    program = lib.mkOption {
      type = lib.types.path;
      default = lib.getExe pkgs.es-de;
      description = "The program to run inside the cage kiosk session.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # -d: don't draw client-side decorations (cleaner kiosk look)
      default = [ "-d" ];
      example = [ "-m last" ];
      description = "Extra arguments passed to cage.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        # Don't error if no input devices are detected at startup
        WLR_LIBINPUT_NO_DEVICES = "1";
      };
      description = "Additional environment variables for the cage session.";
    };

    hideCursor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Replace the cage cursor with a fully transparent theme.
        Useful for pointer-less kiosk setups (e.g. gamepad-only) where
        the default cursor would otherwise be stuck at the centre of the screen.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.cage = {
      enable = true;
      user = cfg.user;
      program = cfg.program;
      extraArguments = cfg.extraArgs;
      environment =
        cfg.environment
        // lib.optionalAttrs cfg.hideCursor {
          XCURSOR_THEME = "transparent";
          XCURSOR_PATH = "${transparentCursorTheme}/share/icons";
        };
      # Use cage from unstable; may have a fix for XWayland/bwrap issues.
      package = unstablePkgs.cage;
    };

    environment.systemPackages = [ pkgs.es-de ];
  };
}
