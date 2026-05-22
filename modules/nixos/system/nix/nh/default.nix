{
  lib,
  config,
  ...
}:
let
  cfg = config.local.system.nix.nh;
in
{
  options.local.system.nix.nh = {
    enable = lib.mkEnableOption "Enable Nix CLI helper";

    configurationName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Flake configuration name to pass to nh with --hostname when it differs from the system hostname.";
      example = "dell-workstation";
    };
  };

  config = lib.mkIf cfg.enable {
    # On NixOS, use the programs.nh module
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/${config.local.user.name}/nix"; # sets NH_FLAKE variable
    };

    # Run programs without nix-shell
    # Usage: $ , cowsay "Hello"
    # It will install cowsay temporily, run the program in your shell, and then
    # remove it from your PATH again afterwards.
    programs.nix-index-database.comma.enable = lib.mkDefault true;
  };
}
