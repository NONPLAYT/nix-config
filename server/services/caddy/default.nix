{ pkgs, config, ... }:

{
  services.caddy = {
    enable = true;

    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-VHm9POg2KixGsMsAcfFFDMK9x6niRJ1iJV9kkSwkSjc=";
    };

    globalConfig = ''
      email admin@bxteam.org
    '';

    environmentFile = config.sops.templates."caddy.env".path;

    virtualHosts = {
      "bxteam.org".extraConfig = ''
        tls { dns cloudflare {env.CF_API_TOKEN} }
        reverse_proxy localhost:3000
      '';

      "influx.bxteam.org".extraConfig = ''
        tls { dns cloudflare {env.CF_API_TOKEN} }
        reverse_proxy localhost:3001
      '';

      "repo.bxteam.org".extraConfig = ''
        tls { dns cloudflare {env.CF_API_TOKEN} }
        reverse_proxy localhost:3002
      '';

      "analytics.bxteam.org".extraConfig = ''
        tls { dns cloudflare {env.CF_API_TOKEN} }
        reverse_proxy localhost:3003
      '';

      "nexon.bxteam.org".extraConfig = ''
        tls { dns cloudflare {env.CF_API_TOKEN} }
        reverse_proxy localhost:6061
      '';

      "dokploy.bxteam.org".extraConfig = ''
        tls { dns cloudflare {env.CF_API_TOKEN} }
        reverse_proxy localhost:6061
      '';

      # catch-all
      "*.bxteam.org".extraConfig = ''
        tls { dns cloudflare {env.CF_API_TOKEN} }
        redir https://bxteam.org{uri} permanent
      '';
    };
  };

  systemd.services.caddy = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
