{ callPackage }:
{
  lemonade-server = callPackage ./server.nix { };
  lemonade-app = callPackage ./app.nix { };
}
