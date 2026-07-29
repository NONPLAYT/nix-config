{ config
, host
, inputs
, lib
, pkgs
, ...
}:

let
  apiPort = 10085;
  vlessPort = 8443;

  nexonHost = "stockholm";

  geoAssets = pkgs.linkFarm "xray-geoassets" {
    "geoip.dat" = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geoip/release/geoip.dat";
      hash = "sha256-bNRcTTpsTSetcDkNORA9bjSjDRF9ui1WTlBMXkP52N0=";
    };
    "geosite.dat" = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/geosite.dat";
      hash = "sha256-dluG5Lau1doaIGMEtVAMdmhof6HfjoMiyKSWHhtnIZA=";
    };
  };

  realityByHost = {
    stockholm = {
      sni = "repo.bxteam.org";
      dest = "127.0.0.1:443";
    };
  };

  reality = realityByHost.${host};

  realityIsLocal = lib.hasPrefix "127.0.0.1" reality.dest;

  xrayConfig = {
    log = {
      loglevel = "warning";
      access = "/var/log/xray/access.log";
      error = "/var/log/xray/error.log";
    };
    stats = { };
    api = {
      tag = "api";
      services = [
        "HandlerService"
        "StatsService"
      ];
    };
    policy = {
      levels."0" = {
        statsUserUplink = true;
        statsUserDownlink = true;
      };
      system = {
        statsInboundUplink = true;
        statsInboundDownlink = true;
      };
    };
    routing = {
      domainStrategy = "IPIfNonMatch";
      rules = [
        {
          inboundTag = [ "api" ];
          outboundTag = "api";
        }
        {
          protocol = [ "bittorrent" ];
          outboundTag = "blocked";
        }
        {
          domain = [ "geosite:category-ru" ];
          outboundTag = "blocked";
        }
        {
          ip = [ "geoip:direct" ];
          outboundTag = "blocked";
        }
      ];
    };
    inbounds = [
      {
        tag = "api";
        listen = "127.0.0.1";
        port = apiPort;
        protocol = "dokodemo-door";
        settings.address = "127.0.0.1";
      }
      {
        tag = "vless-reality";
        listen = "0.0.0.0";
        port = vlessPort;
        protocol = "vless";
        settings = {
          clients = [ ];
          decryption = "none";
        };
        sniffing.enabled = false;
        streamSettings = {
          network = "tcp";
          security = "reality";
          realitySettings = {
            target = reality.dest;
            serverNames = [ reality.sni ];
            privateKey = config.sops.placeholder."${host}/xray/private-key";
            shortIds = [ config.sops.placeholder."${host}/xray/sid" ];
          };
        };
      }
    ];
    outbounds = [
      {
        protocol = "freedom";
        tag = "direct";
      }
      {
        protocol = "blackhole";
        tag = "blocked";
      }
    ];
  };
in
{
  imports = [ inputs.nexon.nixosModules.nexon ];

  services.xray = {
    enable = true;
    settingsFile = config.sops.templates."xray-config.json".path;
  };

  sops.templates."xray-config.json" = {
    content = builtins.toJSON xrayConfig;
    restartUnits = [ "xray.service" ];
  };

  systemd.services.xray.serviceConfig.LogsDirectory = "xray";
  systemd.services.xray.environment.XRAY_LOCATION_ASSET = "${geoAssets}";

  services.logrotate.settings.xray = {
    files = [
      "/var/log/xray/access.log"
      "/var/log/xray/error.log"
    ];
    frequency = "daily";
    rotate = 7;
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    postrotate = "${pkgs.systemd}/bin/systemctl kill -s USR1 xray.service || true";
  };

  services.nexon = lib.mkIf (host == nexonHost) {
    enable = true;
    subListen = "127.0.0.1:3001";
    subBaseURL = "https://nexon.bxteam.org";
  };

  networking.hosts."127.0.0.1" =
    lib.optional realityIsLocal reality.sni
    ++ lib.optional (host == nexonHost) "${host}.bxteam.org";

  networking.firewall.allowedTCPPorts = [ vlessPort ];
}
