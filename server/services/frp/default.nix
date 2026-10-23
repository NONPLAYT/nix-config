{ config, ... }:

let
  bindPort = 7000;

  ports = [
    2023
  ];
in
{
  services.frp.instances."" = {
    enable = true;
    role = "server";
    environmentFiles = [ config.sops.templates."frp.env".path ];
    settings = {
      inherit bindPort;
      auth.token = "{{ .Envs.FRP_TOKEN }}";
      allowPorts = map (port: { single = port; }) ports;
      proxyBindAddr = "127.0.0.1";
      transport.tls.force = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ bindPort ];

  proxy.adminForwards.home-ssh = {
    port = 2023;
    target = "127.0.0.1:2023";
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
