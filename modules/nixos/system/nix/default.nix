{
  lib,
  ...
}:
{
  nix = {
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 1w";
    };

    optimise.automatic = true;
  };
}
