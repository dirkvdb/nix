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
  cfg = config.local.services.hyprmoncfg;
  mkUserHome = mkHome user.name;
in
{
  options.local.services.hyprmoncfg = {
    enable = lib.mkEnableOption "hyprmoncfg monitor profile daemon";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    home.packages = [ pkgs.hyprmoncfg ];

    xdg.configFile."systemd/user/hyprmoncfgd.service".source =
      "${pkgs.hyprmoncfg}/share/systemd/user/hyprmoncfgd.service";
    xdg.configFile."systemd/user/default.target.wants/hyprmoncfgd.service".source =
      "${pkgs.hyprmoncfg}/share/systemd/user/hyprmoncfgd.service";

    # Keep profiles writable for hyprmoncfg, but make Nix authoritative on activation.
    home.activation.syncHyprmoncfgProfiles =
      inputs.home-manager.lib.hm.dag.entryAfter [ "linkGeneration" ]
        ''
          profilesDir="${config.home-manager.users.${user.name}.xdg.configHome}/hyprmoncfg/profiles"
          run mkdir -p "$profilesDir"
          for source in ${./profiles}/*; do
            target="$profilesDir/''${source##*/}"
            run cp --remove-destination --no-preserve=mode "$source" "$target"
            run chmod u+w "$target"
          done

        '';
  });
}
