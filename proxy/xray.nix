{ config, host, lib, pkgs, xctrlNodes, ... }:

let
  apiPort = 10085;

  node = lib.findFirst (n: n.name == host) (throw "no node entry for ${host}") xctrlNodes;

  geoAssets = pkgs.linkFarm "xray-geoassets" {
    "geoip.dat" = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geoip@202608210358/release/geoip.dat";
      hash = "sha256-m8aJcdxYOvG5/xH0NaLvPCnWZfhtSsfzVZGi+S5nMMA=";
    };
    "geosite.dat" = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite@202604152235/release/geosite.dat";
      hash = "sha256-dluG5Lau1doaIGMEtVAMdmhof6HfjoMiyKSWHhtnIZA=";
    };
  };

  realityIsLocal = lib.hasPrefix "127.0.0.1" node.reality.dest;

  inbound = i: {
    tag = "vless-${i.group}";
    listen = "0.0.0.0";
    inherit (i) port;
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
        target = node.reality.dest;
        serverNames = [ node.reality.sni ];
        privateKey = config.sops.placeholder."${host}/xray/private-key";
        shortIds = [ config.sops.placeholder."proxy/nodes/${host}/sid" ];
      };
    };
  };

  settings = {
    log = {
      loglevel = "warning";
      access = "/var/log/xray/access.log";
      error = "/var/log/xray/error.log";
    };
    stats = { };
    api = {
      tag = "api";
      services = [ "HandlerService" "StatsService" ];
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
        { inboundTag = [ "api" ]; outboundTag = "api"; }
        { protocol = [ "bittorrent" ]; outboundTag = "blocked"; }
        { domain = [ "geosite:category-ru" ]; outboundTag = "blocked"; }
        { ip = [ "geoip:direct" ]; outboundTag = "blocked"; }
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
    ] ++ map inbound node.inbounds;
    outbounds = [
      { protocol = "freedom"; tag = "direct"; }
      { protocol = "blackhole"; tag = "blocked"; }
    ];
  };
in
{
  services.xray = {
    enable = true;
    settingsFile = config.sops.templates."xray-config.json".path;
  };

  sops.templates."xray-config.json" = {
    content = builtins.toJSON settings;
    restartUnits = [ "xray.service" ];
  };

  sops.templates."xctrl-token" = {
    content = config.sops.placeholder."proxy/token";
    restartUnits = [ "xray.service" ];
  };

  systemd.services.xray = {
    serviceConfig.LogsDirectory = "xray";
    environment.XRAY_LOCATION_ASSET = "${geoAssets}";
    serviceConfig.LoadCredential = lib.mkForce [
      "config.json:${config.sops.templates."xray-config.json".path}"
      "xctrl-token:${config.sops.templates."xctrl-token".path}"
    ];

    serviceConfig.ExecStartPost = "-${pkgs.writeShellScript "xray-reapply" ''
      ${pkgs.curl}/bin/curl -s -o /dev/null -m 2 http://127.0.0.1:10086/health || exit 0
      exec ${pkgs.curl}/bin/curl -fsS -m 10 -X POST \
        -H "Authorization: Bearer $(< "$CREDENTIALS_DIRECTORY/xctrl-token")" \
        http://127.0.0.1:10086/sync
    ''}";
  };

  services.logrotate.settings.xray = {
    files = [ "/var/log/xray/access.log" "/var/log/xray/error.log" ];
    frequency = "daily";
    rotate = 7;
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    postrotate = "${pkgs.systemd}/bin/systemctl kill -s USR1 xray.service || true";
  };

  networking.hosts."127.0.0.1" = lib.optional realityIsLocal node.reality.sni;
  networking.firewall.allowedTCPPorts = map (i: i.port) node.inbounds;
}
