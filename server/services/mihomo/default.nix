{ config, pkgs, ... }:

let
  finland = {
    name = "finland";
    type = "vless";
    server = "finland.bxteam.org";
    port = 8443;
    uuid = config.sops.placeholder."chain/finland/uuid";
    flow = "xtls-rprx-vision";
    network = "tcp";
    tls = true;
    udp = true;
    "ip-version" = "ipv4";
    servername = "www.google.com";
    "client-fingerprint" = "firefox";
    alpn = [ "h2" ];
    "reality-opts" = {
      "public-key" = config.sops.placeholder."chain/finland/public-key";
      "short-id" = config.sops.placeholder."chain/finland/sid";
    };
  };

  rules = [
    "DOMAIN-SUFFIX,bxteam.org,DIRECT"
    "GEOIP,PRIVATE,DIRECT,no-resolve"
    "GEOSITE,category-game-platforms-download,DIRECT"
    "GEOSITE,sony,DIRECT"
    "GEOSITE,playstation,DIRECT"
    "GEOSITE,category-ru,DIRECT"
    "GEOSITE,youtube,DIRECT"
    "GEOSITE,roblox,finland"
    "IP-ASN,22697,finland,no-resolve"
    "MATCH,finland"
  ];

  mihomoConfig = {
    "socks-port" = 7891;
    "bind-address" = "127.0.0.1";
    mode = "rule";
    "log-level" = "error";
    ipv6 = false;
    "unified-delay" = true;
    "tcp-concurrent" = true;
    "geodata-mode" = true;
    "find-process-mode" = "off";
    dns = {
      enable = true;
      ipv6 = false;
      "default-nameserver" = [ "77.88.8.8" "1.1.1.1" ];
      "proxy-server-nameserver" = [ "https://common.dot.dns.yandex.net/dns-query" ];
      nameserver = [ "https://common.dot.dns.yandex.net/dns-query" ];
      fallback = [ "https://1.1.1.1/dns-query" "https://8.8.8.8/dns-query" ];
      "fallback-filter" = {
        geoip = false;
        ipcidr = [ "127.0.0.0/8" "0.0.0.0/8" ];
      };
    };
    sniffer = {
      enable = true;
      "force-dns-mapping" = true;
      "parse-pure-ip" = true;
      "override-destination" = false;
      "sniffing-timeout" = "100ms";
      sniff = {
        TLS.ports = [ 443 ];
        HTTP.ports = [ 80 8080 ];
        QUIC.ports = [ 443 ];
      };
    };
    proxies = [ finland ];
    inherit rules;
  };
in
{
  systemd.services.mihomo = {
    description = "mihomo smart-routing";
    after = [
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = false;
    serviceConfig = {
      ExecStartPre = pkgs.writeShellScript "mihomo-geodata" ''
        ${pkgs.coreutils}/bin/ln -sfn ${pkgs.v2ray-domain-list-community}/share/v2ray/geosite.dat /var/lib/mihomo/GeoSite.dat
        ${pkgs.coreutils}/bin/ln -sfn ${pkgs.v2ray-geoip}/share/v2ray/geoip.dat /var/lib/mihomo/GeoIP.dat
      '';
      ExecStart = "${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f \${CREDENTIALS_DIRECTORY}/config.yaml";
      LoadCredential = "config.yaml:/etc/mihomo/config.yaml";
      StateDirectory = "mihomo";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services.xray = {
    after = [ "mihomo.service" ];
    wants = [ "mihomo.service" ];
  };

  sops.templates.mihomo-config = {
    content = builtins.toJSON mihomoConfig;
    path = "/etc/mihomo/config.yaml";
    mode = "0600";
  };
}
