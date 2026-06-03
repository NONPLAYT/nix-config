{ config, ... }:

{
  systemd.services."docker-geoipupdate" = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };

  virtualisation.oci-containers.containers.geoipupdate = {
    image = "maxmindinc/geoipupdate:latest";
    environment = {
      GEOIPUPDATE_EDITION_IDS = "GeoLite2-Country";
      GEOIPUPDATE_FREQUENCY = "168";
    };
    environmentFiles = [ config.sops.templates."geoip.env".path ];
    volumes = [ "/var/lib/geoip:/usr/share/GeoIP" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/geoip 0755 root root -"
  ];
}
