os_cmd := if os() == "macos" { "darwin" } else { "os" }

build:
    nh {{ os_cmd }} build .

test:
    nh {{ os_cmd }} test .
    nixcfg-reload

switch:
    nh {{ os_cmd }} switch .

update:
    nix flake update

switch_on_boot:
    nh {{ os_cmd }} boot  .

check:
    nix flake check -L

color-lsp:
    nix-build -E 'with import <nixpkgs> { overlays = [ (final: prev: { color-lsp = prev.callPackage ./pkgs/color-lsp { }; }) ]; }; color-lsp'
