{ lib, ... }:
let
  getDir =
    dir:
    lib.mapAttrs (file: type: if type == "directory" then getDir "${dir}/${file}" else type) (
      builtins.readDir dir
    );

  files =
    dir:
    lib.collect lib.isString (
      lib.mapAttrsRecursive (path: type: lib.concatStringsSep "/" path) (getDir dir)
    );

  getDefaultNix =
    dir:
    map (file: ./. + "/${file}") (builtins.filter (file: baseNameOf file == "default.nix") (files dir));
in
{
  imports = getDefaultNix ./. ++ [ ../common/import.nix ];
}
