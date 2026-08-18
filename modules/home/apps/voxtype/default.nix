{
  lib,
  config,
  pkgs,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.voxtype;
  mkUserHome = mkHome user.name;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable or false;
  isHeadless = config.local.headless or false;
  isHyprlandEnabled = config.local.desktop.hyprland.enable or false;

  # Upstream nixpkgs only builds the base `voxtype` binary; the floating
  # waveform OSD (`voxtype-osd` + `voxtype-osd-gtk4`) is gated behind the
  # `osd-gtk4` Cargo feature, which nixpkgs's package.nix doesn't enable.
  # Build it ourselves so dictation gets a visual overlay instead of running
  # as a silent background daemon. Also turn on `vulkanSupport` (a real
  # package.nix argument) so whisper.cpp uses the Vulkan GPU backend instead
  # of CPU-only inference.
  voxtypeWithOsd =
    (pkgs.voxtype.override { vulkanSupport = true; }).overrideAttrs (old: {
      # NB: `rustPlatform.buildRustPackage`'s `buildFeatures` argument is only
      # read while constructing the derivation; by the time `overrideAttrs`
      # runs, the cargo flags it produces are already baked into the
      # `cargoBuildFeatures`/`cargoCheckFeatures` derivation attributes, which
      # is what the `cargoBuildHook`/`cargoCheckHook` actually read. Those are
      # the attributes we need to extend here.
      cargoBuildFeatures = (old.cargoBuildFeatures or [ ]) ++ [ "osd-gtk4" ];
      cargoCheckFeatures = (old.cargoCheckFeatures or [ ]) ++ [ "osd-gtk4" ];
      buildInputs = (old.buildInputs or [ ]) ++ [
        pkgs.gtk4
        pkgs.gtk4-layer-shell
        pkgs.cairo
        pkgs.glib
      ];
    });
in
{
  options.local.apps.voxtype = {
    enable = lib.mkEnableOption "Voxtype voice dictation with a floating waveform OSD";
  };

  config = lib.mkIf (cfg.enable && isLinux && isDesktop && !isHeadless && isHyprlandEnabled) (mkUserHome {
    services.voxtype = {
      enable = true;
      package = voxtypeWithOsd;
      loadModels = [ "base.en" ];

      settings = {
        # Compositor keybinding (SUPER + SHIFT + X, see
        # ../hyprland/bindings.nix) drives recording via
        # `voxtype record toggle` instead of the built-in evdev hotkey, so
        # no membership in the `input` group is required.
        hotkey.enabled = false;
        state_file = "auto";

        whisper.model = "base.en";

        osd.frontend = "gtk4";

        output.notification.on_transcription = true;
      };
    };

    # The OSD is a separate long-running process from the voxtype daemon;
    # it watches the daemon's state over its state file and shows/hides the
    # waveform overlay automatically, so it needs to stay running rather
    # than being launched per-keypress.
    systemd.user.services.voxtype-osd = {
      Unit = {
        Description = "Voxtype dictation OSD overlay";
        PartOf = [ "default.target" ];
        After = [ "voxtype.service" ];
      };
      Service = {
        Type = "exec";
        ExecStart = "${voxtypeWithOsd}/bin/voxtype-osd";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "default.target" ];
    };
  });
}
