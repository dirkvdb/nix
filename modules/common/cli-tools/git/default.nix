{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.local) user;
  cfg = config.local.cli-tools.git;
  aliases = import ../../../shared/aliases.nix;

in
{
  options.local.cli-tools.git = {
    enable = mkEnableOption "Git configs";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
      gh
    ];

    programs.fish.shellAliases = mkIf (
      user.shell.package == pkgs.fish || config.local.system.shell.fish.enable
    ) aliases.git;
  };
}
