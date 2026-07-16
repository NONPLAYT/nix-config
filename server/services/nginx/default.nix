{ lib, host, ... }:

let
  vhost = port: {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString port}";
  };

  emptyVhost = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      return = "200 '<!DOCTYPE html><html><body></body></html>'";
      extraConfig = ''
        default_type text/html;
      '';
    };
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

    virtualHosts =
      lib.optionalAttrs (host == "finland") {
        "repo.bxteam.org" = vhost 3000;
      }
      // lib.optionalAttrs (host == "moscow") {
        "nexon.bxteam.org" = vhost 3001;
      }
      // lib.optionalAttrs (builtins.elem host [ "finland" "moscow" ]) {
        "${host}.bxteam.org" = emptyVhost;
      };
  };
}
