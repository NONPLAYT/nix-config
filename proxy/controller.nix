{ inputs, pkgs, ... }:

let
  xctrl = inputs.xctrl.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  systemd.services.xctrl = {
    description = "xctrl controller and subscription server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "sops-install-secrets.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "${xctrl}/bin/xctrl serve";
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

  sops.templates.xctrl.restartUnits = [ "xctrl.service" ];

  services.nginx.virtualHosts."sub.bxteam.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3001";
  };
}
