{ config, ... }:

{
  services.kura.runner = {
    enable = true;
    serverUrl = "https://stockholm.bxteam.org";
    tokenFile = config.sops.secrets."home/kura/runner-token".path;
  };

  systemd.services.kura-runner = {
    after = [ "mihomo.service" ];
    wants = [ "mihomo.service" ];
  };
}
