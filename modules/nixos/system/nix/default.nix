{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.local) user;
  sopsEnabled = config.local.apps.sops.enable or false;
in
{
  nix = {
    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    nixfmt
    nix-output-monitor
  ];

  sops.templates."user-nix-conf" = mkIf (user.enable && sopsEnabled) {
    path = "/home/${user.name}/.config/nix/nix.conf";
    owner = user.name;
    mode = "0400";
    content = "access-tokens = github.com=${config.sops.placeholder.github_token}\n";
  };
}
