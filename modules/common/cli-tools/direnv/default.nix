{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.cli-tools.direnv;
in
{
  options.local.cli-tools.direnv = {
    enable = lib.mkEnableOption "Enable direnv";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
        package = pkgs.nix-direnv;
      };
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      enableFishIntegration = lib.mkIf (user.shell.package == pkgs.fish) true;
      enableZshIntegration = lib.mkIf (user.shell.package == pkgs.zsh) true;
    };
  };
}
