{ config, ... }:

let
  umamiPort = 3003;
in
{
  services.umami = {
    enable = true;
    settings = {
      APP_SECRET_FILE = config.sops.secrets."umami/secret-key".path;
      PORT = umamiPort;
    };
    createPostgresqlDatabase = true;
  };

  systemd.services.umami = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };
}
