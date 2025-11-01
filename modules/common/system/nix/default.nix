{
  config,
  ...
}:
let
  inherit (config.local) user;
in
{
  nix = {
    settings = {
      trusted-users = [
        "${user.name}"
      ];
    };
  };
}
