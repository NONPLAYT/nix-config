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
        fi
        ${pkgs.git}/bin/git -C ${repoDir} fetch origin --prune
        ${pkgs.git}/bin/git -C ${repoDir} remote set-head origin --auto
        branch=$(${pkgs.git}/bin/git -C ${repoDir} symbolic-ref --short refs/remotes/origin/HEAD)
        ${pkgs.git}/bin/git -C ${repoDir} reset --hard "$branch"
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
      ${pkgs.git}/bin/git fetch origin --prune
      ${pkgs.git}/bin/git remote set-head origin --auto
      branch=$(${pkgs.git}/bin/git symbolic-ref --short refs/remotes/origin/HEAD)
      ${pkgs.git}/bin/git reset --hard "$branch"
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
