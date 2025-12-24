{
  lib,
  config,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.apps.jan;
in
{
  options.local.apps.jan = {
    enable = lib.mkEnableOption "Install Jan llm desktop app";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with unstablePkgs; [
      jan
    ];
  };
}
