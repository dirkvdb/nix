# Project layout
- `hosts`: Machine specific configurations.
- `modules/nixos`: Nixos specific modules
- `modules/darwin`: Nix-darwin specific modules
- `modules/common`: Modules shared between NixOS and Nix-darwin
- `modules/home`: Home-manager modules
- `pkgs`: custom Nix packages.

# Building the config
To build the NixOS configuration for the current host, you can use the following command:
```bash
just build
```

To perform a validity test for all the configs run:
```bash
just test
```

# Guidelines
After making changes to the configuration, verify that the config still builds
