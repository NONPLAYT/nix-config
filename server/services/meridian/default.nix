{ config, pkgs, ... }:

let
  image = "ghcr.io/bx-team/meridian:latest";
  docker = "${config.virtualisation.docker.package}/bin/docker";
in
{
  systemd.services."docker-meridian" = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };

  virtualisation.oci-containers.containers.meridian = {
    image = image;
    extraOptions = [ "--network=host" ];
    environmentFiles = [ config.sops.templates."meridian.env".path ];
  };

  systemd.services.meridian-update = {
    description = "Pull updates for meridian and restart if changed";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      BEFORE=$(${docker} image inspect --format '{{.Id}}' ${image} 2>/dev/null || echo none)
      ${docker} pull ${image}
      AFTER=$(${docker} image inspect --format '{{.Id}}' ${image})
      if [ "$BEFORE" != "$AFTER" ]; then
        systemctl restart docker-meridian.service
      fi
    '';
  };

  systemd.timers.meridian-update = {
    description = "Check meridian updates every 30 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      Unit = "meridian-update.service";
    };
  };
}
