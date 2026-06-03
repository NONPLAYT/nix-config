{ config, ... }:

{
  systemd.services."docker-frps" = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };

  virtualisation.oci-containers.containers.frps = {
    image = "snowdreamtech/frps:latest";
    extraOptions = [ "--network=host" ];
    volumes = [
      "${config.sops.templates."frps.toml".path}:/etc/frp/frps.toml:ro"
    ];
  };
}
