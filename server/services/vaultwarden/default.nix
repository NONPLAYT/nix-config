{ config, tunnel, ... }:

{
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "/var/backup/vaultwarden";
    environmentFile = config.sops.templates."vaultwarden.env".path;
    config = {
      DOMAIN = "https://vault.bxteam.org";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ENABLE_WEBSOCKET = true;
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      IP_HEADER = "CF-Connecting-IP";
    };
  };

  services.cloudflared.tunnels.${tunnel}.ingress."vault.bxteam.org" = "http://127.0.0.1:8222";

  sops.templates."vaultwarden.env" = {
    owner = "vaultwarden";
    mode = "0400";
    restartUnits = [ "vaultwarden.service" ];
    content = ''
      ADMIN_TOKEN='${config.sops.placeholder."stockholm/vaultwarden/admin-token"}'
    '';
  };
}
