{
  lib,
  config,
  pkgs,
  mkHome,
  inputs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.pi-coding-agent;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.pi-coding-agent = {
    enable = lib.mkEnableOption "Pi coding agent";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.pi-coding-agent = {
      enable = true;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
      extraPackages = [ pkgs.nodejs_24 ];
      settings.packages = [ "npm:pi-agents" ];
    };
  });
}
