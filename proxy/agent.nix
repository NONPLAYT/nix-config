{ host, inputs, lib, pkgs, xctrlApiPath, xctrlNodes, ... }:

let
  xctrl = inputs.xctrl.packages.${pkgs.stdenv.hostPlatform.system}.default;
  node = lib.findFirst (n: n.name == host) (throw "no node entry for ${host}") xctrlNodes;
in
{
  environment.systemPackages = [ xctrl ];

  systemd.services.xctrl-agent = {
    description = "xctrl node agent";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-install-secrets.service" "xray.service" ];
    wants = [ "xray.service" ];
    serviceConfig = {
      ExecStart = "${xctrl}/bin/xctrl agent";
      User = "xctrl";
      Group = "xctrl";
      StateDirectory = "xctrl";
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

  sops.templates.xctrl.restartUnits = [ "xctrl-agent.service" ];

  services.nginx.virtualHosts.${node.fqdn} = {
    enableACME = true;
    forceSSL = true;
    locations."${xctrlApiPath}/".proxyPass = "http://127.0.0.1:10086/";
  };
}
