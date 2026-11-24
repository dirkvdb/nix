{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  userName = "vdboerd";
  userHome = "/home/${userName}";
in
{
  imports = [
    inputs.stylix.homeModules.stylix
    inputs.zen-browser.homeModules.default

    ../../modules/common/options
    ../../modules/common/theme
    ../../modules/home/import.nix
  ];

  disabledModules = [ ../../modules/home/apps/neovim/default.nix ];

  config = {
    home = {
      username = userName;
      homeDirectory = userHome;
      stateVersion = "26.05";
    };

    # Enable XDG but disable mime (which can pull in cursor/desktop deps)
    xdg = {
      enable = true;
      mimeApps.enable = lib.mkForce false;
      systemDirs.data = lib.mkForce [ ];
    };

    # Stylix theme - enabled for terminal/CLI only, no desktop features
    stylix = {
      enable = true;
      autoEnable = false;
      base16Scheme = config.local.theme.base16Scheme;
      # Only enable terminal/CLI targets (no GUI/desktop)
      targets.bat.enable = true;
      targets.btop.enable = true;
      targets.fish.enable = true;
    };

    # Disable dconf completely (requires dbus which isn't available in Docker)
    dconf.enable = false;

    # Configure using the local options
    local = {
      user = {
        enable = true;
        name = userName;
        homeDir = userHome;
        home-manager.enable = true;
        shell.package = pkgs.fish;
      };

      # Disable desktop to prevent cursor/icon themes from being installed
      desktop.enable = false;
      headless = true;

      # The cluster's OpenSSH client rejects this directive even for other hosts.
      ssh.supportsWarnWeakCrypto = false;

      # Use everforest theme (only terminal/CLI styling, no GUI)
      theme.preset = "everforest";

      home-manager = {
        standalone = true;
        configName = "hpc";
      };

      system.dev = {
        enable = true;
        llmClis.enable = false;
        # nix-rootless can't chmod while unpacking, so source builds fail.
        uncachedPackages.enable = false;
        # devenv 2.x embeds Nix and can't see the rewritten nix-rootless store.
        devenv.enable = false;
      };

      apps = {
        direnv = {
          enable = true;
          rootlessStoreWorkaround = true;
        };

      };
    };

    # Atuin times out on NFS mounts
    programs.atuin.enable = lib.mkForce false;
    programs.fish.shellAliases.buildnode = "srun --ntasks-per-node=64 --pty bash -l";

    # Compute nodes (and nix-rootless) may export an XDG_RUNTIME_DIR such as
    # /run/user/<uid> that does not exist or is not writable, which breaks
    # tools like devenv. Fall back to a private directory in /tmp (not $HOME,
    # since sockets on NFS are unreliable).
    programs.fish.shellInit = ''
      if not test -d "$XDG_RUNTIME_DIR" -a -w "$XDG_RUNTIME_DIR" -a -x "$XDG_RUNTIME_DIR"
          set -l fallback_runtime_dir /tmp/xdg-runtime-(id -u)
          mkdir -p -m 700 $fallback_runtime_dir 2>/dev/null
          if test -d $fallback_runtime_dir -a -O $fallback_runtime_dir
              chmod 700 $fallback_runtime_dir
              set -gx XDG_RUNTIME_DIR $fallback_runtime_dir
          end
      end
    '';
  };
}
