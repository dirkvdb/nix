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
just check
```

# Guidelines
When adding new files, also add them to git otherwise the flake will not consider the files
After making changes to the configuration, verify that the config still builds using `just build`. Never switch to the config.

# MCP context servers
The `mcp-nixos` MCP server is available as a context server. Use it to look up real NixOS/Home Manager/nix-darwin package names, options, and configuration details instead of guessing. It provides two tools:
- `nix` — search and inspect NixOS packages (130K+), system options (23K+), Home Manager options (5K+), nix-darwin options (1K+), flakes, Noogle function signatures, Nixvim options, wiki articles, and binary cache status.
- `nix_versions` — look up historical package versions with their nixpkgs commit hashes.

# Missing commands
When commands like `python` are missing prefix them with the , to execute them e.g. `, python`
