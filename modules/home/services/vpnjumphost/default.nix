# Home-manager module for the VITO VPN jumphost.
#
# Provides a systemd user service when local.services.vpnjumphost.enable = true:
#
#   vito-vpn.service
#     ExecStartPre — vito-vpn-cookie-refresh:
#       * Probes the VPN endpoint with the existing cookie (fast path, no UI).
#       * If the cookie is missing or rejected, opens Firefox via Playwright
#         so the user can complete VITO SSO + Microsoft Authenticator MFA.
#     ExecStart — vito-vpn-start:
#       * exec openconnect --protocol=f5 --cookie-on-stdin --script-tun
#             --script "ocproxy -D <socksPort> -k <keepalive>"
#         openconnect spawns ocproxy as its --script-tun peer; ocproxy serves
#         SOCKS5 on 127.0.0.1:<socksPort>.  No TUN device, no sudo, no root.
#     Restart=on-failure — on a network flap the cookie is usually still valid,
#     so the probe passes quickly and the tunnel reconnects without a browser.
#
# When local.services.vpnjumphost.pac.enable = true, the PAC file is referenced
# directly from the Nix store via a file:// URL. No HTTP server is needed.
# local.system.network.proxy.pacUrl is set automatically.
#
# Credentials (username + password) are read from sops secrets at runtime:
#   /run/secrets/vpnjumphost/username
#   /run/secrets/vpnjumphost/password
#
# When local.apps.winboat.enable is true, ocproxy is passed -g so the SOCKS5
# listener binds to 0.0.0.0 instead of 127.0.0.1, making it reachable from
# inside the WinBoat Docker container via the Docker bridge gateway IP.

{
  config,
  lib,
  pkgs,
  mkHome,
  ...
}:

let
  inherit (config.local) user;
  cfg = config.local.services.vpnjumphost;
  winboatEnabled = config.local.apps.winboat.enable or false;
  mkUserHome = mkHome user.name;

  cookieFilePath = "${user.homeDir}/.local/state/vpn-jumphost/cookie";
  usernameSecretPath = "/run/secrets/vpnjumphost/username";
  passwordSecretPath = "/run/secrets/vpnjumphost/password";

  # --------------------------------------------------------------------------
  # Playwright / Firefox setup.
  # playwright-driver carries browsers.json (browser version metadata) and
  # playwright-driver.browsers carries the actual browser binaries.
  # --------------------------------------------------------------------------
  python = pkgs.python3.withPackages (ps: [ ps.playwright ]);

  playwrightMeta = builtins.fromJSON (builtins.readFile "${pkgs.playwright-driver}/browsers.json");
  firefoxRev = (lib.findFirst (b: b.name == "firefox") null playwrightMeta.browsers).revision;
  playwrightBrowsers = pkgs.playwright-driver.browsers;
  firefoxBin = "${playwrightBrowsers}/firefox-${firefoxRev}/firefox/firefox";

  # Python scripts embedded in the Nix store.
  fetchCookiePy = pkgs.writeText "fetch-vpn-cookie.py" (builtins.readFile ./fetch-vpn-cookie.py);
  cookieCheckPy = pkgs.writeText "vito-vpn-cookie-check.py" (builtins.readFile ./cookie-check.py);

  # --------------------------------------------------------------------------
  # ExecStartPre: validate existing cookie; launch browser only when needed.
  # --------------------------------------------------------------------------
  cookieRefreshScript = pkgs.writeShellScript "vito-vpn-cookie-refresh" ''
    set -euo pipefail

    COOKIE_FILE=${lib.escapeShellArg cookieFilePath}

    # Fast path: probe the VPN endpoint with the existing cookie.
    # Exits 0 immediately (no browser) when the cookie is still valid.
    if ${python}/bin/python3 ${cookieCheckPy} \
        "$COOKIE_FILE" ${lib.escapeShellArg cfg.vpnUrl} 2>/dev/null; then
      printf 'vito-vpn: existing cookie is valid\n' >&2
      exit 0
    fi

    printf 'vito-vpn: cookie missing or rejected — opening browser for fresh login...\n' >&2
    mkdir -p "$(dirname "$COOKIE_FILE")"

    export PLAYWRIGHT_BROWSERS_PATH=${lib.escapeShellArg (toString playwrightBrowsers)}
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=1
    export PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH=${lib.escapeShellArg firefoxBin}

    ${python}/bin/python3 ${fetchCookiePy} \
      --output "$COOKIE_FILE" \
      --username-file ${lib.escapeShellArg usernameSecretPath} \
      --password-file ${lib.escapeShellArg passwordSecretPath}
  '';

  # --------------------------------------------------------------------------
  # ExecStart: exec openconnect — this process becomes the service from
  # systemd's perspective. SIGTERM from systemd → openconnect → ocproxy.
  # --------------------------------------------------------------------------
  vpnStartScript = pkgs.writeShellScript "vito-vpn-start" ''
    set -Eeuo pipefail

    COOKIE_FILE=${lib.escapeShellArg cookieFilePath}

    if [[ ! -s "$COOKIE_FILE" ]]; then
      printf 'vito-vpn: no F5 session cookie found at %s\n' "$COOKIE_FILE" >&2
      exit 1
    fi

    printf 'vito-vpn: starting openconnect+ocproxy (url=%s socks=127.0.0.1:%s)\n' \
      ${lib.escapeShellArg cfg.vpnUrl} \
      ${lib.escapeShellArg (toString cfg.socksPort)} >&2

    # exec replaces the shell; SIGTERM from systemd reaches openconnect directly.
    # openconnect tears down the tunnel and kills ocproxy (its --script-tun child)
    # via the socketpair when it exits — nothing to clean up manually.
    # When winboat is enabled, -g makes ocproxy bind to 0.0.0.0 so the
    # WinBoat Docker container can reach the SOCKS5 proxy via the Docker
    # bridge gateway IP.  Otherwise ocproxy binds to 127.0.0.1 only.
    exec ${pkgs.openconnect}/bin/openconnect \
      --protocol=${lib.escapeShellArg cfg.vpnProtocol} \
      --cookie-on-stdin \
      --script-tun \
      --script ${lib.escapeShellArg "${pkgs.ocproxy}/bin/ocproxy${if winboatEnabled then " -g" else ""} -D ${toString cfg.socksPort} -k ${toString cfg.ocproxyKeepalive}"} \
      ${lib.escapeShellArg cfg.vpnUrl} < "$COOKIE_FILE"
  '';

in
{
  options.local.system.network.proxy.pacUrl = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "file:// URL pointing to the PAC file in the Nix store. Set automatically when local.services.vpnjumphost.pac.enable is true.";
  };

  options.local.services.vpnjumphost = {
    enable = lib.mkEnableOption "VITO VPN jumphost (openconnect + ocproxy SOCKS5 userspace tunnel)";

    vpnUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://byod.vito.be";
      description = "F5 VPN endpoint URL.";
    };

    vpnProtocol = lib.mkOption {
      type = lib.types.str;
      default = "f5";
      description = ''OpenConnect protocol identifier. Always "f5" for VITO BYOD.'';
    };

    socksPort = lib.mkOption {
      type = lib.types.port;
      default = 1080;
      description = "SOCKS5 listen port for ocproxy. Binds to 127.0.0.1 only.";
    };

    ocproxyKeepalive = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
      description = "TCP keepalive interval (seconds) passed to ocproxy via -k. Prevents idle NAT timeouts from silently killing long-lived tunnelled connections (SSH, VS Code Remote, …).";
    };

    pac = {
      enable = lib.mkEnableOption "PAC proxy auto-configuration (sets pacUrl to a file:// store path)";

      file = lib.mkOption {
        type = lib.types.path;
        default = ./proxy.pac;
        description = ''
          Path to the PAC file. Defaults to the bundled proxy.pac.
          The file is added to the Nix store at evaluation time; changes
          take effect after rebuilding.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        local.system.network.proxy.pacUrl = lib.mkIf cfg.pac.enable "file://${cfg.pac.file}";
      }
      (mkUserHome {
        systemd.user.services.vito-vpn = {
          Unit = {
            Description = "VPN jumphost (openconnect + ocproxy SOCKS5 userspace tunnel)";
            # graphical-session.target: Playwright needs DISPLAY / WAYLAND_DISPLAY to
            # open a browser window when the cookie needs renewal. On reconnects where
            # the existing cookie is still valid, ExecStartPre exits immediately without
            # touching the browser.
            After = [
              "network-online.target"
              "graphical-session.target"
            ];
            Wants = [
              "network-online.target"
              "graphical-session.target"
            ];
          };

          Service = {
            Type = "simple";

            # Step 1 — validate cookie; open browser for fresh login only if needed.
            ExecStartPre = "${cookieRefreshScript}";

            # Step 2 — exec openconnect (replaces the shell; SIGTERM hits openconnect
            # directly and tears down ocproxy with it via the --script-tun socketpair).
            ExecStart = "${vpnStartScript}";

            # Reconnect automatically on network flap. The cookie probe in ExecStartPre
            # passes quickly (no browser) when the cookie is still valid.
            Restart = "on-failure";
            RestartSec = 15;
            # Cap restart loops: at most 3 automatic restarts per 10 minutes.
            StartLimitIntervalSec = 600;
            StartLimitBurst = 3;

            # Allow up to 6 minutes for ExecStartPre (10 s cookie probe + browser MFA).
            TimeoutStartSec = 360;
            KillSignal = "SIGTERM";
            PrivateTmp = true;
          };

          Install = {
            # Auto-start with the user's graphical session.
            WantedBy = [ "graphical-session.target" ];
          };
        };

      })
    ]
  );
}
