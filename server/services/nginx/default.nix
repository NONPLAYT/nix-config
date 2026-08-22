{ ... }:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@bxteam.org";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.nginx = {
    enable = true;
    clientMaxBodySize = "150m";
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
  };
}
