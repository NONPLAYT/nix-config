{ ... }:

let
  vhost = port: {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@bxteam.org";
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    virtualHosts = {
      "repo.bxteam.org" = vhost 3000;
      "nexon.bxteam.org" = vhost 3001;
    };
  };
}
