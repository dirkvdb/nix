{ lib, config, ... }:
let
  inherit (lib) mkIf mkAfter;
  inherit (config.local) user;

  sopsEnabled = config.local.apps.sops.enable or false;
in
{
  config = mkIf (user.enable && sopsEnabled) {
    sops.templates."nix-github-access-tokens" = {
      owner = "root";
      mode = "0400";
      content = "access-tokens = github.com=${config.sops.placeholder.github_token}\n";
    };

    nix.extraOptions = mkAfter ''
      !include ${config.sops.templates."nix-github-access-tokens".path}
    '';
  };
}
