{ config, ... }:

{
  systemd.services."docker-meridian" = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };

  virtualisation.oci-containers.containers.meridian = {
    image = "nonplay/meridian:latest";
    extraOptions = [ "--network=host" ];
    environmentFiles = [ config.sops.templates."meridian.env".path ];
  };
}
