{
  lib,
  config,
  mkHome,
  unstablePkgs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.opencode;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.opencode.enable = lib.mkEnableOption "OpenCode AI coding agent";

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.opencode = {
      enable = true;
      package = unstablePkgs.opencode;
      settings = {
        "$schema" = "https://opencode.ai/config.json";
        enabled_providers = [
          "openai"
          "github-copilot"
        ];
      };
    };
  });
}
