{ config, tunnel, ... }:

let
  kura = config.services.kura.server;
in
{
  services.kura.server = {
    enable = true;
    domain = "git.bxteam.org";
    environmentFile = config.sops.templates."kura.env".path;

    nginx.enable = false;

    settings.ssh.host = "stockholm.bxteam.org";

    builds = {
      enable = true;
      endpoint = "https://6c19bad5e3a3ea0820bb7b1fa745e6c2.r2.cloudflarestorage.com";
      bucket = "builds";
      publicUrl = "https://files.bxteam.org";
    };
  };

  services.cloudflared.tunnels.${tunnel}.ingress."git.bxteam.org" =
    "http://${kura.address}:${toString kura.port}";

  services.nginx.virtualHosts."stockholm.bxteam.org".locations."/api/" = {
    proxyPass = "http://${kura.address}:${toString kura.port}";
    extraConfig = ''
      proxy_buffering off;
      proxy_request_buffering off;
      proxy_read_timeout ${toString kura.uploadTimeout}s;
      client_max_body_size ${toString kura.builds.maxUploadBytes};
    '';
  };

  sops.templates."kura.env" = {
    owner = "kura";
    mode = "0400";
    restartUnits = [ "kura-server.service" ];
    content = ''
      KURA_SECRET_KEY=${config.sops.placeholder."stockholm/kura/secret-key"}
      KURA_S3_ACCESS_KEY_ID=${config.sops.placeholder."stockholm/kura/s3-access-key-id"}
      KURA_S3_SECRET_ACCESS_KEY=${config.sops.placeholder."stockholm/kura/s3-secret-access-key"}
    '';
  };
}
