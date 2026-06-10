{ config, pkgs, ... }:

let
  image = "ghcr.io/bx-team/cinder:latest";
  docker = "${config.virtualisation.docker.package}/bin/docker";
in
{
  systemd.services."docker-cinder" = {
    after = [ "network.target" "sops-install-secrets.service" "postgresql.service" "redis-default.service" "clickhouse.service" ];
    requires = [ "sops-install-secrets.service" "postgresql.service" "redis-default.service" "clickhouse.service" ];
  };

  virtualisation.oci-containers.containers.cinder = {
    image = image;
    extraOptions = [ "--network=host" ];
    environmentFiles = [ config.sops.templates."cinder.env".path ];
  };

  systemd.services.cinder-update = {
    description = "Pull updates for cinder and restart if changed";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      BEFORE=$(${docker} image inspect --format '{{.Id}}' ${image} 2>/dev/null || echo none)
      ${docker} pull ${image}
      AFTER=$(${docker} image inspect --format '{{.Id}}' ${image})
      if [ "$BEFORE" != "$AFTER" ]; then
        systemctl restart docker-cinder.service
      fi
    '';
  };

  systemd.timers.cinder-update = {
    description = "Check cinder updates every 30 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      Unit = "cinder-update.service";
    };
  };
}
