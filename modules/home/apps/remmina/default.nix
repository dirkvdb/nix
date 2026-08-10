{
  lib,
  pkgs,
  config,
  inputs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.remmina;
  mkUserHome = mkHome user.name;

  mkConnectionFile =
    name: conn:
    let
      settings = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${toString v}") conn);
      text = ''
        [remmina]
        colordepth = 99;
        resolution_mode = 1;
        quality = 2;
        network = "autodetect";
        sound = "off";
        ignore-tls-errors = 1;
        ${settings}
      '';
    in
    pkgs.writeText "${name}.remmina" text;

  # Remmina rewrites these files in place (e.g. to save a login password),
  # so they must be regular, writable files rather than read-only store
  # symlinks. Only seed the file the first time it's missing; once created
  # it's left alone on every subsequent activation so Remmina/user changes
  # (like saved passwords) are never overwritten or fought over.
  mkConnectionActivation =
    name: conn: ''
      target="$HOME/.local/share/remmina/${name}.remmina"
      if [ ! -e "$target" ]; then
        mkdir -p "$HOME/.local/share/remmina"
        install -m644 "${mkConnectionFile name conn}" "$target"
        chmod u+w "$target"
      fi
    '';
in
{
  options.local.apps.remmina = {
    enable = lib.mkEnableOption "Remmina remote desktop client connections";

    connections = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = { };
      description = "Remmina connection profiles keyed by filename (without .remmina)";
    };
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    home.packages = [ pkgs.remmina ];

    home.activation.remminaConnections = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.concatStringsSep "\n" (lib.mapAttrsToList mkConnectionActivation cfg.connections)
    );
  });
}
