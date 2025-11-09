os_cmd := if os() == "macos" { "darwin" } else { "os" }

build:
    nh {{os_cmd}} build .

test:
    nh {{os_cmd}} test  .

switch:
    nh {{os_cmd}} switch .

build_mb:
    nixos-rebuild build --flake .#macbook-pro-m2-nixos --impure

switch_mb:
    nixos-rebuild switch --flake .#macbook-pro-m2-nixos --impure

update:
    nix flake update

switch_on_boot:
    nh {{os_cmd}} boot  .
