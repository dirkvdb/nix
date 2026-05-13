{
  lib,
  config,
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

    sops.secrets = {
      "vpn/nordvpn.conf" = { };
      "sonarr/api_key" = { };
      "radarr/api_key" = { };
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
        wgConfFile = config.sops.secrets."vpn/nordvpn.conf".path;
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
        package = unstablePkgs.sonarr;
        config = {
          apiKey._secret = config.sops.secrets."sonarr/api_key".path;
          hostConfig.password._secret = config.sops.secrets."arr/password".path;
        };
      };

      radarr = {
        enable = true;
        package = unstablePkgs.radarr;
        config = {
          apiKey._secret = config.sops.secrets."radarr/api_key".path;
          hostConfig.password._secret = config.sops.secrets."arr/password".path;
        };
      };

      lidarr = {
        enable = true;
        package = unstablePkgs.lidarr;
        config = {
          apiKey._secret = config.sops.secrets."lidarr/api_key".path;
          hostConfig.password._secret = config.sops.secrets."arr/password".path;
        };
      };

      prowlarr = {
        enable = true;
        package = unstablePkgs.prowlarr;
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
        serverConfig.Preferences.WebUI.Password_PBKDF2 =
          ''@ByteArray(GOT/oxX4EohRRMf1FOoGAA==:nNroSP4qegzAps3jIK/qQsWAXuC/F7slljkkN4UdVbbFO6/O7QYPhi36ZBqqE/k8Ra9BWFCaxiLs0Yq5XqjFhg==)'';
        serverConfig.Preferences.WebUI.AuthSubnetWhitelistEnabled = true;
        serverConfig.Preferences.WebUI.AuthSubnetWhitelist = "192.168.1.0/24";
      };

      usenetClients.sabnzbd = {
        enable = true;
        package = unstablePkgs.sabnzbd;
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
        package = unstablePkgs.jellyfin;
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
