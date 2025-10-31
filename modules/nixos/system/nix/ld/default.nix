{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.local.system.nix.ld;
in
{
  options.local.system.nix.ld = {
    enable = lib.mkEnableOption "nix-ld for running dynamically linked executables";
  };

  config = lib.mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Common libraries needed by dynamically linked executables
        stdenv.cc.cc.lib
        zlib
        glibc
        openssl
        curl
        expat
        fontconfig
        freetype
        fribidi
        harfbuzz
        libGL
        libxkbcommon
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
        xorg.libXrandr
      ];
    };
  };
}
