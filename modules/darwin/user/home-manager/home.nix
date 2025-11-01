{
  user,
  pkgs,
  lib,
  ...
}:
with lib;
{
  config = {
    programs.home-manager.enable = true;

    home = {
      username = "${user.name}";
      homeDirectory = "${user.homeDir}";
      stateVersion = "25.05";

      extraActivationPath = with pkgs; [
        rsync
      ];

      packages = with pkgs; [
        alt-tab-macos
        iina
      ];

      # # https://github.com/nix-community/home-manager/issues/1341#issuecomment-1870352014
      # activation.trampolineApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      #   ${builtins.readFile ./trampoline-apps.sh}
      #   fromDir="$HOME/Applications/Home Manager Apps"
      #   toDir="$HOME/Applications/Home Manager Trampolines"
      #   sync_trampolines "$fromDir" "$toDir"
      # '';
    };
  };
}
