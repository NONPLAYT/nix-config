{ tunnel, ... }:

{
  services.reposilite = {
    enable = true;
    settings = {
      port = 3000;
      hostname = "127.0.0.1";
    };
  };

  services.cloudflared.tunnels.${tunnel}.ingress."repo.bxteam.org" = "http://127.0.0.1:3000";

  services.nginx.virtualHosts."stockholm.bxteam.org".locations."/".proxyPass =
    "http://127.0.0.1:3000";
}
