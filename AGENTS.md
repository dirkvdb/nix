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

# Quadlets
Always add Quadlets with a web interface to Homepage. Import `modules/quadlets/homepage.nix` in the Quadlet module and define a `services.homepage-dashboard.quadletEntries` entry when the Quadlet is enabled, following the existing modules. Include a working URL, description, icon, and a `siteMonitor` URL where supported. Respect existing access restrictions; for loopback-only interfaces, use the local tunnel URL and clearly indicate that an SSH tunnel is required rather than exposing the service just for Homepage.

# MCP context servers
The `mcp-nixos` MCP server is available as a context server. Use it to look up real NixOS/Home Manager/nix-darwin package names, options, and configuration details instead of guessing. It provides two tools:
- `nix` — search and inspect NixOS packages (130K+), system options (23K+), Home Manager options (5K+), nix-darwin options (1K+), flakes, Noogle function signatures, Nixvim options, wiki articles, and binary cache status.
- `nix_versions` — look up historical package versions with their nixpkgs commit hashes.

# Missing commands
When commands like `python` are missing prefix them with the , to execute them e.g. `, python`
