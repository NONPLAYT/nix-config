{ config, pkgs, ... }:

let
  repoDir = "/var/lib/bx-code";
  bunPkg = pkgs.bun;
in
{
  systemd.services.cinder = {
    description = "BX cinder worker";
    after = [ "network.target" "sops-install-secrets.service" "postgresql.service" "redis-default.service" "clickhouse.service" ];
    requires = [ "sops-install-secrets.service" "postgresql.service" "redis-default.service" "clickhouse.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      WorkingDirectory = repoDir;
      EnvironmentFile = config.sops.templates."cinder.env".path;
      Restart = "on-failure";
      RestartSec = "5s";
      ExecStartPre = pkgs.writeShellScript "cinder-pull" ''
        set -e
        if [ ! -d "${repoDir}/.git" ]; then
          ${pkgs.git}/bin/git clone https://github.com/BX-Team/code.git ${repoDir}
        else
          ${pkgs.git}/bin/git -C ${repoDir} pull --ff-only
        fi
        cd ${repoDir}
        ${bunPkg}/bin/bun install --frozen-lockfile --production --ignore-scripts
      '';
      ExecStart = "${bunPkg}/bin/bun run apps/cinder/index.ts";
    };
  };

  systemd.services.cinder-update = {
    description = "Pull updates for cinder and restart if changed";
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      cd ${repoDir}
      BEFORE=$(${pkgs.git}/bin/git rev-parse HEAD)
      ${pkgs.git}/bin/git pull --ff-only
      AFTER=$(${pkgs.git}/bin/git rev-parse HEAD)
      if [ "$BEFORE" != "$AFTER" ]; then
        ${bunPkg}/bin/bun install --frozen-lockfile --production --ignore-scripts
        systemctl restart cinder.service
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
