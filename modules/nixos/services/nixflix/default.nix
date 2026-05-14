{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.local.services.nixflix;
in
{
  options.local.services.nixflix = {
    enable = lib.mkEnableOption "nixflix media server stack";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 ];

    services.recyclarr.package = unstablePkgs.recyclarr;
    services.sonarr.package = unstablePkgs.sonarr;
    services.radarr.package = unstablePkgs.radarr;
    services.lidarr.package = unstablePkgs.lidarr;
    services.prowlarr.package = unstablePkgs.prowlarr;
    services.sabnzbd.package = unstablePkgs.sabnzbd;
    services.jellyfin.package = unstablePkgs.jellyfin;
    services.jellyseerr.package = unstablePkgs.jellyseerr;
    services.bazarr.package = unstablePkgs.bazarr;

    # Bazarr: subtitle manager that integrates with Sonarr/Radarr.
    # Runs as the shared `media` group so it can write subtitle
    # files next to the media owned by the other *arr services.
    services.bazarr = {
      enable = true;
      group = "media";
      listenPort = 6787;
    };
    users.users.bazarr.extraGroups = [ "media" ];

    # Seed Bazarr's config.yaml with API keys (its own + Sonarr/Radarr)
    # and wire it up to Sonarr/Radarr before each start. Bazarr only
    # rewrites the file when values change, so this is idempotent and
    # leaves user-managed fields (providers, languages, etc.) untouched.
    systemd.services.bazarr.serviceConfig.ExecStartPre = [
      (
        "+"
        + (pkgs.writeShellScript "bazarr-seed-config" ''
          set -eu
          CONFIG_DIR="/var/lib/bazarr/config"
          CONFIG_FILE="$CONFIG_DIR/config.yaml"
          mkdir -p "$CONFIG_DIR"
          [ -f "$CONFIG_FILE" ] || : > "$CONFIG_FILE"

          BAZARR_APIKEY="$(cat ${config.sops.secrets."bazarr/api_key".path})"
          SONARR_APIKEY="$(cat ${config.sops.secrets."sonarr/api_key".path})"
          RADARR_APIKEY="$(cat ${config.sops.secrets."radarr/api_key".path})"
          OS_USERNAME="$(cat ${config.sops.secrets."bazarr/opensubtitles_username".path})"
          OS_PASSWORD="$(cat ${config.sops.secrets."bazarr/opensubtitles_password".path})"
          SUBDL_APIKEY="$(cat ${config.sops.secrets."bazarr/subdl_api_key".path})"
          export BAZARR_APIKEY SONARR_APIKEY RADARR_APIKEY OS_USERNAME OS_PASSWORD SUBDL_APIKEY

          ${pkgs.yq-go}/bin/yq -i '
            .auth.apikey = strenv(BAZARR_APIKEY)
            | .auth.type = null
            | .general.use_sonarr = true
            | .general.use_radarr = true
            | .general.enabled_providers = ["opensubtitlescom", "subdl"]
            | .sonarr.ip = "127.0.0.1"
            | .sonarr.port = 8989
            | .sonarr.base_url = "/"
            | .sonarr.ssl = false
            | .sonarr.apikey = strenv(SONARR_APIKEY)
            | .radarr.ip = "127.0.0.1"
            | .radarr.port = 7878
            | .radarr.base_url = "/"
            | .radarr.ssl = false
            | .radarr.apikey = strenv(RADARR_APIKEY)
            | .opensubtitlescom.username = strenv(OS_USERNAME)
            | .opensubtitlescom.password = strenv(OS_PASSWORD)
            | .opensubtitlescom.use_hash = true
            | .opensubtitlescom.include_ai_translated = false
            | .opensubtitlescom.include_machine_translated = false
            | .subdl.api_key = strenv(SUBDL_APIKEY)
          ' "$CONFIG_FILE"

          chown -R bazarr:media "$CONFIG_DIR"
          chmod 0640 "$CONFIG_FILE"
        '')
      )
    ];

    # Idempotently create a "Dutch" language profile via Bazarr's REST API.
    # The settings endpoint deletes any profile not present in the submitted
    # list, so we GET the current profiles, append Dutch only if missing,
    # and POST the merged list back. Enabled languages are merged the same way.
    systemd.services.bazarr-language-profile = {
      description = "Bootstrap Bazarr Dutch language profile";
      after = [ "bazarr.service" ];
      wants = [ "bazarr.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.curl
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
      };
      script = ''
        set -eu
        API_KEY="$(cat ${config.sops.secrets."bazarr/api_key".path})"
        BASE="http://127.0.0.1:6787"
        AUTH=(-H "X-API-KEY: $API_KEY")

        # Wait for Bazarr to be reachable (up to ~2 min).
        for i in $(seq 1 60); do
          if curl -sf "''${AUTH[@]}" "$BASE/api/system/status" >/dev/null; then
            break
          fi
          sleep 2
        done

        PROFILES="$(curl -sf "''${AUTH[@]}" "$BASE/api/system/languages/profiles")"
        if echo "$PROFILES" | jq -e '.[] | select(.name == "Dutch")' >/dev/null; then
          echo "Dutch language profile already exists."
        else
          NEXT_ID="$(echo "$PROFILES" | jq '([.[].profileId] | max // 0) + 1')"
          NEW_PROFILES="$(echo "$PROFILES" | jq --argjson id "$NEXT_ID" '. + [{
            profileId: $id,
            name: "Dutch",
            cutoff: null,
            items: [{
              id: 1,
              language: "nl",
              audio_exclude: "False",
              hi: "False",
              forced: "False",
              audio_only_include: "False"
            }],
            mustContain: [],
            mustNotContain: [],
            originalFormat: null,
            tag: null
          }]')"

          # Merge "nl" into the currently enabled languages so the profile is usable.
          ENABLED="$(curl -sf "''${AUTH[@]}" "$BASE/api/system/languages" \
            | jq -r '.[] | select(.enabled == true) | .code2')"
          ENABLED_WITH_NL="$(printf '%s\nnl\n' "$ENABLED" | sort -u | sed '/^$/d')"

          ARGS=()
          while IFS= read -r code; do
            ARGS+=(--data-urlencode "languages-enabled=$code")
          done <<< "$ENABLED_WITH_NL"
          ARGS+=(--data-urlencode "languages-profiles=$NEW_PROFILES")

          curl -sf -X POST "''${AUTH[@]}" "''${ARGS[@]}" "$BASE/api/system/settings"
          echo "Created Dutch language profile (profileId=$NEXT_ID)."
          PROFILES="$(curl -sf "''${AUTH[@]}" "$BASE/api/system/languages/profiles")"
        fi

        # Set Dutch as the default profile for new series and movies.
        DUTCH_ID="$(echo "$PROFILES" | jq '.[] | select(.name == "Dutch") | .profileId')"
        curl -sf -X POST "''${AUTH[@]}" \
          --data-urlencode "settings-general-serie_default_enabled=true" \
          --data-urlencode "settings-general-serie_default_profile=$DUTCH_ID" \
          --data-urlencode "settings-general-movie_default_enabled=true" \
          --data-urlencode "settings-general-movie_default_profile=$DUTCH_ID" \
          "$BASE/api/system/settings"
        echo "Set Dutch (profileId=$DUTCH_ID) as default profile for series and movies."
      '';
    };

    services.nginx.virtualHosts."bazarr.arr" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:6787";
        recommendedProxySettings = true;
        proxyWebsockets = true;
        extraConfig = ''
          proxy_redirect off;
        '';
      };
    };

    # nixflix's mkVirtualHost defaults `proxyWebsockets` to false, which
    # breaks the SignalR connection the *arr UIs use for live updates
    # ("Could not connect to SignalR, UI won't update" health check).
    # Force WebSocket upgrade on each vhost.
    services.nginx.virtualHosts."sonarr.arr".locations."/".proxyWebsockets = lib.mkForce true;
    services.nginx.virtualHosts."radarr.arr".locations."/".proxyWebsockets = lib.mkForce true;
    services.nginx.virtualHosts."lidarr.arr".locations."/".proxyWebsockets = lib.mkForce true;
    services.nginx.virtualHosts."prowlarr.arr".locations."/".proxyWebsockets = lib.mkForce true;

    # Stable's recyclarr module still passes `--app-data`, which was removed
    # in recyclarr 8.x. Rewrite ExecStart to the 8.x-compatible invocation.
    systemd.services.recyclarr.serviceConfig.ExecStart =
      lib.mkForce "${lib.getExe unstablePkgs.recyclarr} sync --config /var/lib/recyclarr/config.json";

    sops.secrets = {
      "vpn/nordvpn-be.conf" = { };
      "sonarr/api_key" = { };
      "radarr/api_key" = { };
      "bazarr/api_key" = { };
      "bazarr/opensubtitles_username" = { };
      "bazarr/opensubtitles_password" = { };
      "bazarr/subdl_api_key" = { };
      "prowlarr/api_key" = { };
      "jellyfin/api_key" = { };
      "arr/password" = { };
      "sabnzbd/api_key" = { };
      "sabnzbd/nzb_key" = { };
      "usenet/eweka/username" = { };
      "usenet/eweka/password" = { };
      "lidarr/api_key" = { };
      "seerr/api_key" = { };
      "rutracker/username" = { };
      "rutracker/password" = { };
      "eztvl/username" = { };
      "eztvl/password" = { };
    };

    nixflix = {
      enable = true;
      theme = {
        enable = true;
        name = "nord";
      };

      vpn = {
        enable = true;
        wgConfFile = config.sops.secrets."vpn/nordvpn-be.conf".path;
        accessibleFrom = [ "192.168.1.0/24" ];
      };

      mediaDir = "/nas/media";
      downloadsDir = "/nas/downloads";
      mediaUsers = [ "dirk" ];

      flaresolverr.enable = true;

      nginx = {
        enable = true;
        domain = "arr";
        addHostsEntries = false;
      };

      sonarr = {
        enable = true;
        config = {
          apiKey._secret = config.sops.secrets."sonarr/api_key".path;
          hostConfig.password._secret = config.sops.secrets."arr/password".path;
        };
      };

      radarr = {
        enable = true;
        config = {
          apiKey._secret = config.sops.secrets."radarr/api_key".path;
          hostConfig.password._secret = config.sops.secrets."arr/password".path;
        };
      };

      # one-time UI step:
      # - Radarr: configure the language for kids profile
      # - Sonarr: Add a Custom Format with a single condition that requires the language to be Dutch, and set its score to 100 in the Kids profile. This way, only Dutch releases will meet the minimum score threshold for automatic upgrades in that profile.

      recyclarr = {
        enable = true;
        radarrQuality = "4K";
        sonarrQuality = "4K";
        config.radarr.radarr = {
          base_url = "http://127.0.0.1:7878";
          api_key._secret = config.sops.secrets."radarr/api_key".path;
          quality_profiles = [
            {
              name = "Kids";
              upgrade = {
                allowed = true;
                until_quality = "HDTV-1080p";
              };
              qualities = [
                {
                  name = "Raw-HD";
                  enabled = false;
                }
                {
                  name = "BR-DISK";
                  enabled = false;
                }
                { name = "Remux-2160p"; }
                { name = "Bluray-2160p"; }
                {
                  name = "WEB 2160p";
                  qualities = [
                    "WEBRip-2160p"
                    "WEBDL-2160p"
                  ];
                }
                { name = "HDTV-2160p"; }
                { name = "Remux-1080p"; }
                { name = "Bluray-1080p"; }
                {
                  name = "WEB 1080p";
                  qualities = [
                    "WEBRip-1080p"
                    "WEBDL-1080p"
                  ];
                }
                { name = "HDTV-1080p"; }
                { name = "Bluray-720p"; }
                {
                  name = "WEB 720p";
                  qualities = [
                    "WEBRip-720p"
                    "WEBDL-720p"
                  ];
                }
                {
                  name = "HDTV-720p";
                  enabled = false;
                }
              ];
            }
          ];
        };
        config.sonarr.sonarr = {
          base_url = "http://127.0.0.1:8989";
          api_key._secret = config.sops.secrets."sonarr/api_key".path;
          quality_profiles = [
            {
              name = "Kids";
              upgrade = {
                allowed = true;
                until_quality = "HDTV-1080p";
              };
              qualities = [
                {
                  name = "Raw-HD";
                  enabled = false;
                }
                { name = "Bluray-2160p Remux"; }
                { name = "Bluray-2160p"; }
                {
                  name = "WEB 2160p";
                  qualities = [
                    "WEBRip-2160p"
                    "WEBDL-2160p"
                  ];
                }
                { name = "HDTV-2160p"; }
                { name = "Bluray-1080p Remux"; }
                { name = "Bluray-1080p"; }
                {
                  name = "WEB 1080p";
                  qualities = [
                    "WEBRip-1080p"
                    "WEBDL-1080p"
                  ];
                }
                { name = "HDTV-1080p"; }
                { name = "Bluray-720p"; }
                {
                  name = "WEB 720p";
                  qualities = [
                    "WEBRip-720p"
                    "WEBDL-720p"
                  ];
                }
                {
                  name = "HDTV-720p";
                  enabled = false;
                }
              ];
            }
          ];
        };
      };

      lidarr = {
        enable = true;
        config = {
          apiKey._secret = config.sops.secrets."lidarr/api_key".path;
          hostConfig.password._secret = config.sops.secrets."arr/password".path;
        };
      };

      prowlarr = {
        enable = true;
        config = {
          apiKey._secret = config.sops.secrets."prowlarr/api_key".path;
          hostConfig.password._secret = config.sops.secrets."arr/password".path;
          indexers = [
            {
              name = "RuTracker.org";
              enable = true;
              username._secret = config.sops.secrets."rutracker/username".path;
              password._secret = config.sops.secrets."rutracker/password".path;
              russianLetters = true;
            }
            {
              name = "Generic Newznab";
              enable = true;
              redirect = true;
              priority = 1;
              baseUrl = "http://192.168.1.13:8383/newznab";
            }
            {
              name = "BT.etree";
              enable = true;
              baseUrl = "https://bt.etree.org/";
            }
            {
              name = "The Pirate Bay";
              enable = true;
              baseUrl = "https://thepiratebay.org/";
            }
            {
              name = "MixtapeTorrent";
              enable = true;
              baseUrl = "http://www.mixtapetorrent.com/";
            }
            # {
            #   name = "EZTV";
            #   enable = true;
            #   baseUrl = "https://eztvx.to/";
            #   tags = [ "flaresolverr" ];
            # }
            # {
            #   name = "EZTVL";
            #   enable = true;
            #   baseUrl = "https://eztvx.to/";
            #   tags = [ "flaresolverr" ];
            #   username._secret = config.sops.secrets."eztvl/username".path;
            #   password._secret = config.sops.secrets."eztvl/password".path;
            # }
          ];
        };
      };

      torrentClients.qbittorrent = {
        enable = true;
        password._secret = config.sops.secrets."arr/password".path;
        serverConfig.Preferences.WebUI.Username = config.local.user.name;
        serverConfig.Preferences.WebUI.Password_PBKDF2 = "@ByteArray(GOT/oxX4EohRRMf1FOoGAA==:nNroSP4qegzAps3jIK/qQsWAXuC/F7slljkkN4UdVbbFO6/O7QYPhi36ZBqqE/k8Ra9BWFCaxiLs0Yq5XqjFhg==)";
        serverConfig.Preferences.WebUI.AuthSubnetWhitelistEnabled = true;
        serverConfig.Preferences.WebUI.AuthSubnetWhitelist = "192.168.1.0/24";
      };

      usenetClients.sabnzbd = {
        enable = true;
        settings = {
          misc = {
            api_key._secret = config.sops.secrets."sabnzbd/api_key".path;
            nzb_key._secret = config.sops.secrets."sabnzbd/nzb_key".path;
          };
          servers = [
            {
              name = "Eweka";
              host = "news.eweka.nl";
              port = 563;
              username._secret = config.sops.secrets."usenet/eweka/username".path;
              password._secret = config.sops.secrets."usenet/eweka/password".path;
              connections = 20;
              ssl = true;
              priority = 0;
              retention = 0;
            }
          ];
        };
      };

      seerr = {
        enable = true;
        package = unstablePkgs.seerr;
        apiKey._secret = config.sops.secrets."seerr/api_key".path;
      };

      jellyfin = {
        enable = true;
        openFirewall = true;
        apiKey._secret = config.sops.secrets."jellyfin/api_key".path;
        encoding = {
          enableHardwareEncoding = true;
          hardwareAccelerationType = "qsv";
          hardwareDecodingCodecs = [
            "h264"
            "hevc"
            "mpeg2video"
            "vc1"
            "vp9"
          ];
        };
        users.dirk = {
          password._secret = config.sops.secrets."arr/password".path;
          policy.isAdministrator = true;
          mutable = false;
        };
      };
    };
  };
}
