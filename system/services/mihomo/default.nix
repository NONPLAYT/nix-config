{ config, pkgs, ... }:

{
  systemd.services.mihomo = {
    description = "mihomo";
    after = [
      "network.target"
      "sops-install-secrets.service"
    ];
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = false;
    serviceConfig = {
      ExecStart = "${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f \${CREDENTIALS_DIRECTORY}/config.yaml";
      LoadCredential = "config.yaml:/etc/mihomo/config.yaml";
      CapabilityBoundingSet = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
      ];
      AmbientCapabilities = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
      ];
      StateDirectory = "mihomo";
      NoNewPrivileges = false;
    };
  };

  sops.templates.mihomo-config = {
    content = ''
      allow-lan: true
      mixed-port: 7890
      mode: rule
      log-level: debug
      external-controller: 127.0.0.1:9090
      unified-delay: true
      tcp-concurrent: true

      dns:
        enable: true
        enhanced-mode: fake-ip
        default-nameserver:
        - 1.1.1.1
        - 8.8.8.8
        nameserver:
        - 1.1.1.1
        - 8.8.8.8
        nameserver-policy:
          +.google.com: 111.88.96.50
          '*.google.com': 111.88.96.50
        fake-ip-range: 198.18.0.1/16
        fake-ip-filter:
        - '*.lan'
        - stun.*.*.*
        - stun.*.*
        - '*.local'
        - +.arpa
        - +.bxteam.org
        - localhost.*
        - time.*
        - pool.ntp.org
        - '*.msftncsi.com'
        - '*.msftconnecttest.com'

      tun:
        enable: true
        stack: system
        auto-route: true
        auto-detect-interface: true
        dns-hijack:
        - any:53
        strict-route: true
        route-exclude-address:
          - 224.0.0.0/3
          - 10.0.0.0/8
          - 127.0.0.0/8
          - 100.64.0.0/10
          - 172.16.0.0/12
          - 169.254.0.0/16
          - 192.168.0.0/16

      proxies:
        - name: vless
          type: vless
          server: ${config.sops.placeholder."home/mihomo/server"}
          port: 2025
          uuid: ${config.sops.placeholder."home/mihomo/uuid"}
          udp: true
          tcp-opts: {}
          servername: yandex.ru
          client-fingerprint: firefox
          reality-opts:
            public-key: ${config.sops.placeholder."home/mihomo/pub-key"}
            short-id: ${config.sops.placeholder."home/mihomo/sid"}

      rules:
        - GEOIP,PRIVATE,DIRECT
        - GEOSITE,category-ru,DIRECT
        - MATCH,vless
    '';
    path = "/etc/mihomo/config.yaml";
    mode = "0600";
  };
}
