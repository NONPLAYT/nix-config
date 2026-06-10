{ config, pkgs, ... }:

let
  image = "ghcr.io/bx-team/influx:latest";
  docker = "${config.virtualisation.docker.package}/bin/docker";
in
{
  systemd.services."docker-influx" = {
    after = [ "network.target" "sops-install-secrets.service" "postgresql.service" "redis-default.service" ];
    requires = [ "sops-install-secrets.service" "postgresql.service" "redis-default.service" ];
  };

  virtualisation.oci-containers.containers.influx = {
    image = image;
    extraOptions = [ "--network=host" ];
    environmentFiles = [ config.sops.templates."influx.env".path ];
  };

  systemd.services.influx-update = {
    description = "Pull updates for influx and restart if changed";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      BEFORE=$(${docker} image inspect --format '{{.Id}}' ${image} 2>/dev/null || echo none)
      ${docker} pull ${image}
      AFTER=$(${docker} image inspect --format '{{.Id}}' ${image})
      if [ "$BEFORE" != "$AFTER" ]; then
        systemctl restart docker-influx.service
      fi
    '';
  };

  systemd.timers.influx-update = {
    description = "Check influx updates every 30 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      Unit = "influx-update.service";
    };
  };
}
