{ config, ... }:

{
  services.frp.instances."" = {
    enable = true;
    role = "client";
    environmentFiles = [ config.sops.templates."frp.env".path ];
    settings = {
      serverAddr = "stockholm.bxteam.org";
      serverPort = 7000;
      auth.token = "{{ .Envs.FRP_TOKEN }}";

      proxies = [
        {
          name = "ssh";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 2022;
          remotePort = 2023;
        }
      ];
    };
  };

  systemd.services.frp = {
    after = [ "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
  };

  sops.templates."frp.env" = {
    restartUnits = [ "frp.service" ];
    content = "FRP_TOKEN=${config.sops.placeholder."frp/token"}";
  };
}
