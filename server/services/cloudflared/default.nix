{ config, lib, ... }:

let
  tunnel = "ba696ace-61f2-4c75-881d-5654a1665f4a";
in
{
  _module.args.tunnel = tunnel;

  _module.args.tunneled = {
    enableACME = lib.mkForce false;
    forceSSL = lib.mkForce false;
    listenAddresses = [ "127.0.0.1" ];
  };

  services.cloudflared = {
    enable = true;
    tunnels.${tunnel} = {
      credentialsFile = config.sops.templates."cloudflared.json".path;
      default = "http_status:404";
    };
  };

  systemd.services."cloudflared-tunnel-${tunnel}" = {
    after = [ "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
  };

  sops.templates."cloudflared.json" = {
    restartUnits = [ "cloudflared-tunnel-${tunnel}.service" ];
    content = builtins.toJSON {
      AccountTag = "6c19bad5e3a3ea0820bb7b1fa745e6c2";
      TunnelID = tunnel;
      TunnelSecret = config.sops.placeholder."stockholm/cloudflared/tunnel-secret";
    };
  };
}
