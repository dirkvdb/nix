{
  pkgs,
  ...
}:
{
  nix = {
    optimise.automatic = true;
  };

  environment.systemPackages = with pkgs; [
    nixfmt-rfc-style
    nix-output-monitor
  ];
}
