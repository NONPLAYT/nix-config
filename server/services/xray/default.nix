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

  nexonHost = "moscow";

  role =
    {
      moscow = "master";
      finland = "exit";
    }.${host};

  apiListen = if role == "master" then "127.0.0.1" else "0.0.0.0";

  reality =
    {
      finland = { sni = "www.google.com"; dest = "www.google.com:443"; };
      moscow = { sni = "moscow.bxteam.org"; dest = "127.0.0.1:443"; };
    }.${host};

  chainClients = lib.optionals (role == "exit") [
    {
      email = "chain-master";
      id = config.sops.placeholder."chain/${host}/uuid";
      flow = "xtls-rprx-vision";
    }
  ];

  outbounds =
    if role == "master" then
      [
        {
          protocol = "socks";
          tag = "proxy";
          settings.servers = [
            {
              address = "127.0.0.1";
              port = 7891;
            }
          ];
        }
        {
          protocol = "freedom";
          tag = "direct";
        }
        {
          protocol = "blackhole";
          tag = "blocked";
        }
      ]
    else
      [
        {
          protocol = "freedom";
          tag = "direct";
        }
        {
          protocol = "blackhole";
          tag = "blocked";
        }
      ];

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
      domainStrategy = "AsIs";
      rules = [
        {
          inboundTag = [ "api" ];
          outboundTag = "api";
        }
        {
          protocol = [ "bittorrent" ];
          outboundTag = "blocked";
        }
      ];
    };
    inbounds = [
      {
        tag = "api";
        listen = apiListen;
        port = apiPort;
        protocol = "dokodemo-door";
        settings.address = apiListen;
      }
      {
        tag = "vless-reality";
        listen = "0.0.0.0";
        port = vlessPort;
        protocol = "vless";
        settings = {
          clients = chainClients;
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
    outbounds = outbounds;
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

  networking.hosts = lib.mkIf (host == nexonHost) {
    "127.0.0.1" = [ "${host}.bxteam.org" ];
  };

  networking.firewall = {
    allowedTCPPorts = [ vlessPort ];
    extraInputRules = lib.mkIf (role == "exit") ''
      ip saddr 46.8.21.129 tcp dport ${toString apiPort} accept
    '';
  };
}
