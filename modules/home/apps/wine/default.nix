{
  config,
  pkgs,
  lib,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.wine;
  mkUserHome = mkHome user.name;
  isHeadless = config.local.headless;
in
{
  options.local.apps.wine = {
    enable = lib.mkEnableOption "Wine for running 64-bit Windows binaries";

    package = lib.mkOption {
      type = lib.types.package;
      # WoW64 build: a single 64-bit Wine that also runs 32-bit binaries via
      # the new-WoW64 layer, with Gecko, Mono, OpenGL/Vulkan and audio support.
      default = pkgs.wineWow64Packages.stable;
      defaultText = lib.literalExpression "pkgs.wineWow64Packages.stable";
      description = "Wine package to install. Defaults to the WoW64 stable build (64-bit capable).";
    };

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "${user.homeDir}/.wine64";
      description = "Default WINEPREFIX directory for the 64-bit Wine environment.";
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux && !isHeadless) (mkUserHome {
    home.packages = [
      cfg.package
      pkgs.winetricks
      pkgs.cabextract # extract Windows .cab files for winetricks
      pkgs.samba # provides ntlm_auth, avoids login warnings
    ];

    home.sessionVariables = {
      WINEARCH = "win64";
      WINEPREFIX = cfg.prefix;
    };
  });
}
