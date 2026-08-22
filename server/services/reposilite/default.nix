{ ... }:

{
  services.reposilite = {
    enable = true;
    settings = {
      port = 3000;
      hostname = "127.0.0.1";
    };
  };

  services.nginx.virtualHosts."repo.bxteam.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3000";
  };
}
