os_cmd := if os() == "macos" { "darwin" } else { "os" }

build:
    nh {{os_cmd}} build .

test:
    nh {{os_cmd}} test  .

switch:
    nh {{os_cmd}} switch  .

update:
    nix flake update

switch_on_boot:
    nh {{os_cmd}} boot  .
