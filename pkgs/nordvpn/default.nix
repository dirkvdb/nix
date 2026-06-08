{
  callPackage,
  fetchFromGitHub,
  lib,
  symlinkJoin,
}:
let
  version = "5.0.0";

  common = {
    inherit version;

    src = fetchFromGitHub {
      owner = "NordSecurity";
      repo = "nordvpn-linux";
      tag = version;
      hash = "sha256-PHxaYsOGOiEhghNApr/ScfIx0OGtNzS1geruK4QzXMg=";
    };

    # rec so that changelog can reference homepage
    meta = rec {
      homepage = "https://github.com/NordSecurity/nordvpn-linux";
      changelog = "${homepage}/releases/tag/${version}";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
    };

    desktopItemArgs = {
      categories = [ "Network" ];
      genericName = "VPN Client";
      icon = "nordvpn";
      type = "Application";
    };
  };
in
symlinkJoin {
  pname = "nordvpn";
  inherit version;

  paths = [
    (callPackage ./cli.nix common)
    (callPackage ./gui.nix common)
  ];

  passthru = {
    cli = callPackage ./cli.nix common;
    gui = callPackage ./gui.nix common;
  };

  meta = common.meta // {
    mainProgram = "nordvpn";
    description = "NordVPN client and GUI for Linux";
    longDescription = ''
      NordVPN CLI and GUI applications for Linux.
      This package currently does not support meshnet.
      Additionally, if `networking.firewall.enable = true;`,
      then also set `networking.firewall.checkReversePath = "loose";`.
      The closed-source nordwhisper protocol is also not supported.
    '';
  };
}
