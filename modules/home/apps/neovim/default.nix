{
  lib,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.neovim;
  mkUserHome = mkHome user.name;
in
{
  options.local.apps.neovim = {
    enable = lib.mkEnableOption "Neovim text editor";
  };

  config = lib.mkIf cfg.enable (mkUserHome {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      withNodeJs = true;
      withPython3 = true;
    };
  });
}
