{ config, inputs, pkgs, ... }:

let
  rfc-bot = inputs.rfc.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  systemd.services.rfc-bot = {
    description = "RFC prak signup telegram bot";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "sops-install-secrets.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "${rfc-bot}/bin/rfc-bot";
      EnvironmentFile = config.sops.templates."rfc-bot.env".path;
      Environment = [
        "DB_PATH=/var/lib/rfc-bot/prak.db"
        "TIMEZONE=Europe/Moscow"
      ];
      User = "rfc-bot";
      Group = "rfc-bot";
      WorkingDirectory = "/var/lib/rfc-bot";
      StateDirectory = "rfc-bot";
      StateDirectoryMode = "0750";
      Restart = "on-failure";
      RestartSec = 5;

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      SystemCallFilter = [ "@system-service" ];
    };
  };

  sops.templates."rfc-bot.env" = {
    owner = "rfc-bot";
    mode = "0400";
    restartUnits = [ "rfc-bot.service" ];
    content = ''
      BOT_TOKEN=${config.sops.placeholder."stockholm/rfc-bot/bot-token"}
      ADMIN_CHAT_ID=${config.sops.placeholder."stockholm/rfc-bot/admin-chat-id"}
      ADMIN_IDS=${config.sops.placeholder."stockholm/rfc-bot/admin-ids"}
    '';
  };

  users.groups.rfc-bot = { };
  users.users.rfc-bot = {
    isSystemUser = true;
    group = "rfc-bot";
  };
}
