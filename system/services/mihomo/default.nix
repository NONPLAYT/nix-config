{ config, ... }:

{
  sops.templates."mihomo.yaml" = {
    owner = "nonplay";
    content = ''
      mixed-port: 7890
      allow-lan: false
      mode: rule
      log-level: info
      ipv6: false
      external-controller: 127.0.0.1:9090

      tun:
        enable: true
        stack: gvisor
        auto-route: true
        auto-detect-interface: true
        dns-hijack:
          - any:53
          - tcp://any:53

      dns:
        enable: true
        ipv6: false
        enhanced-mode: fake-ip
        fake-ip-range: 198.18.0.1/16
        listen: 0.0.0.0:1053
        default-nameserver:
          - 1.1.1.1
          - 8.8.8.8
        nameserver:
          - https://1.1.1.1/dns-query
          - https://8.8.8.8/dns-query
        proxy-server-nameserver:
          - https://1.1.1.1/dns-query
          - https://8.8.8.8/dns-query
        nameserver-policy:
          '+.google.com': '111.88.96.50'
          '*.google.com': '111.88.96.50'
        fake-ip-filter:
          - "*.lan"
          - "+.local"

        sniffer:
          enable: true
          force-dns-mapping: true
          parse-pure-ip: true
          override-destination: true
          sniff:
            TLS:
              ports: [443, 2025]
            HTTP:
              ports: [80]
            QUIC:
              ports: [2026]
          skip-domain:
            - '+.push.apple.com'
            - 'dns.google'

      proxy-providers:
        nexon:
          type: http
          url: "${config.sops.placeholder."home/mihomo/nexon"}"
          interval: 86400
          path: ./providers/nexon.yaml
          health-check:
            enable: true
            url: https://www.gstatic.com/generate_204
            interval: 300

        wiyba:
          type: http
          url: "${config.sops.placeholder."home/mihomo/wiyba"}"
          interval: 86400
          path: ./providers/wiyba.yaml
          health-check:
            enable: true
            url: https://www.gstatic.com/generate_204
            interval: 300

      proxy-groups:
        - name: PROXY
          type: select
          use:
            - nexon
            - wiyba
        - name: AUTO
          type: url-test
          use:
            - nexon
            - wiyba
          url: https://www.gstatic.com/generate_204
          interval: 300

      rule-providers:
        private-domains:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/private.mrs
          path: ./ruleset/geosite-private.mrs
          proxy: PROXY
          interval: 2592000
        category-ru:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/category-ru.mrs
          path: ./ruleset/category-ru.mrs
          proxy: PROXY
          interval: 86400
        whitelist:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/whitelist.mrs
          path: ./ruleset/whitelist.mrs
          proxy: PROXY
          interval: 86400
        microsoft:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/microsoft.mrs
          path: ./ruleset/microsoft.mrs
          proxy: PROXY
          interval: 86400
        apple:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/apple.mrs
          path: ./ruleset/apple.mrs
          proxy: PROXY
          interval: 86400
        google-play:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/google-play.mrs
          path: ./ruleset/google-play.mrs
          proxy: PROXY
          interval: 86400
        epicgames:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/epicgames.mrs
          path: ./ruleset/epicgames.mrs
          proxy: PROXY
          interval: 86400
        origin:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/origin.mrs
          path: ./ruleset/origin.mrs
          proxy: PROXY
          interval: 86400
        riot:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/riot.mrs
          path: ./ruleset/riot.mrs
          proxy: PROXY
          interval: 86400
        escapefromtarkov:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/escapefromtarkov.mrs
          path: ./ruleset/escapefromtarkov.mrs
          proxy: PROXY
          interval: 86400
        steam:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/steam.mrs
          path: ./ruleset/steam.mrs
          proxy: PROXY
          interval: 86400
        twitch:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/twitch.mrs
          path: ./ruleset/twitch.mrs
          proxy: PROXY
          interval: 86400
        pinterest:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/pinterest.mrs
          path: ./ruleset/pinterest.mrs
          proxy: PROXY
          interval: 86400
        faceit:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/faceit.mrs
          path: ./ruleset/faceit.mrs
          proxy: PROXY
          interval: 86400
        win-spy:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/win-spy.mrs
          path: ./ruleset/win-spy.mrs
          proxy: PROXY
          interval: 86400
        category-ads:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/category-ads.mrs
          path: ./ruleset/category-ads.mrs
          proxy: PROXY
          interval: 86400
        torrent-domains:
          type: http
          behavior: domain
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geosite/release/mihomo/torrent.mrs
          path: ./ruleset/torrent-domains.mrs
          proxy: PROXY
          interval: 86400
        private-ips:
          type: http
          behavior: ipcidr
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geoip/release/mihomo/private.mrs
          path: ./ruleset/geoip-private.mrs
          proxy: PROXY
          interval: 2592000
        direct-ips:
          type: http
          behavior: ipcidr
          format: mrs
          url: https://cdn.jsdelivr.net/gh/hydraponique/roscomvpn-geoip/release/mihomo/direct.mrs
          path: ./ruleset/direct-ips.mrs
          proxy: PROXY
          interval: 86400
        torrent-clients:
          type: http
          behavior: classical
          format: yaml
          url: https://raw.githubusercontent.com/legiz-ru/mihomo-rule-sets/main/other/torrent-clients.yaml
          path: ./ruleset/torrent-clients.yaml
          proxy: PROXY
          interval: 86400
        games:
          type: http
          behavior: classical
          format: yaml
          url: https://raw.githubusercontent.com/roscomvpn/custom-category/release/mihomo/games.yaml
          path: ./ruleset/games.yaml
          proxy: PROXY
          interval: 86400
        ru-apps:
          type: http
          behavior: classical
          format: yaml
          url: https://raw.githubusercontent.com/roscomvpn/custom-category/release/mihomo/ru-apps.yaml
          path: ./ruleset/ru-apps.yaml
          proxy: PROXY
          interval: 86400

      rules:
        # SSH Servers
        - DOMAIN,finland.bxteam.org,DIRECT

        # --- Блокировки (высший приоритет) ---
        - RULE-SET,private-ips,DIRECT,no-resolve
        - RULE-SET,private-domains,DIRECT
        - RULE-SET,win-spy,REJECT-DROP

        # --- Через прокси ---
        - PROCESS-NAME,Discord.exe,PROXY
        - PROCESS-NAME,DiscordDevelopment.exe,PROXY
        - PROCESS-NAME,DiscordCanary.exe,PROXY
        - PROCESS-NAME,DiscordPTB.exe,PROXY
        - PROCESS-NAME,Update.exe,PROXY
        - PROCESS-NAME,Telegram.exe,PROXY
        - IP-ASN,62041,PROXY
        - GEOSITE,spotify,PROXY
        - GEOSITE,rutracker,PROXY
        - GEOSITE,openai,PROXY
        - GEOSITE,anthropic,PROXY
        - GEOSITE,github,PROXY
        - GEOSITE,youtube,PROXY
        - GEOSITE,twitter,PROXY
        - GEOSITE,whatsapp,PROXY
        - GEOSITE,tiktok,PROXY
        - GEOSITE,instagram,PROXY
        - GEOSITE,supercell,PROXY

        # --- Игры (DIRECT — без VPN) ---
        - RULE-SET,epicgames,DIRECT
        - RULE-SET,origin,DIRECT
        - RULE-SET,riot,DIRECT
        - RULE-SET,escapefromtarkov,DIRECT
        - RULE-SET,steam,DIRECT
        - RULE-SET,faceit,DIRECT
        - RULE-SET,games,DIRECT

        # --- DIRECT ---
        - RULE-SET,torrent-domains,DIRECT
        - RULE-SET,torrent-clients,DIRECT
        - RULE-SET,twitch,DIRECT
        - RULE-SET,microsoft,DIRECT
        - RULE-SET,apple,DIRECT
        - RULE-SET,google-play,DIRECT
        - RULE-SET,pinterest,DIRECT
        - RULE-SET,category-ru,DIRECT
        - RULE-SET,whitelist,DIRECT
        - RULE-SET,ru-apps,DIRECT
        - RULE-SET,direct-ips,DIRECT

        # Fallback
        - MATCH,PROXY
    '';
  };

  services.mihomo = {
    enable = true;
    tunMode = true;
    configFile = config.sops.templates."mihomo.yaml".path;
  };
}
