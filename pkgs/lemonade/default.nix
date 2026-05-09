{ callPackage }:
let
  lemonade-web-app-bundle = callPackage ./web-app-bundle.nix { };
in
{
  lemonade-server = callPackage ./server.nix { inherit lemonade-web-app-bundle; };
  lemonade-app = callPackage ./app.nix { };
  inherit lemonade-web-app-bundle;
}
