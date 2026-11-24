{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.direnv;
  mkUserHome = mkHome user.name;

  # The direnv package ships a fish "vendor_conf.d" snippet
  # (share/fish/vendor_conf.d/direnv.fish -> `direnv hook fish | source`)
  # that fish auto-loads for every interactive shell via XDG_DATA_DIRS,
  # regardless of home-manager's `enableFishIntegration` option below (that
  # option only controls a redundant snippet home-manager would otherwise
  # add itself). We use devenv's native shell hook for fish activation
  # instead, so strip direnv's own fish hook out of the package to stop it
  # auto-activating .envrc files in fish.
  direnvNoFishHook =
    if cfg.rootlessStoreWorkaround then
      # Avoid copying store files where nix-rootless cannot set their permissions.
      pkgs.symlinkJoin {
        name = "direnv-no-fish-hook-${pkgs.direnv.version}";
        inherit (pkgs.direnv) pname version meta;
        paths = [ pkgs.direnv ];
        postBuild = ''
          rm -f $out/share/fish/vendor_conf.d/direnv.fish
        '';
      }
    else
      pkgs.runCommand "direnv-no-fish-hook" { } ''
        cp -r ${pkgs.direnv} $out
        chmod -R u+w $out
        rm -f $out/share/fish/vendor_conf.d/direnv.fish
      '';
in
{
  options.local.apps.direnv = {
    enable = lib.mkEnableOption "Enable direnv";
    rootlessStoreWorkaround = lib.mkEnableOption "the symlink-based direnv package for nix-rootless stores";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.direnv = {
      enable = true;
      package = direnvNoFishHook;
      enableFishIntegration = lib.mkForce false;

      config = {
        global = {
          hide_env_diff = true;
          log_filter = "^$";
        };
      };

      nix-direnv = {
        enable = true;
        package = pkgs.nix-direnv;
      };
    };
  });
}
