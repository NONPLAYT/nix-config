{ config, pkgs, ... }:

let
  bindPort = 8444;

  mtg = pkgs.buildGoModule (finalAttrs: {
    pname = "mtg";
    version = "2.2.8";
    src = pkgs.fetchFromGitHub {
      owner = "9seconds";
      repo = "mtg";
      tag = "v${finalAttrs.version}";
      hash = "sha256-qRqyA40+w2dWZ+rfieniaRoKqQ9ZdTRD/sq6otDSL9g=";
    };
    vendorHash = "sha256-SHD9Hm3FUGG4YihWb0ZS1sUaAz76Ub8LR6llvnz4gEc=";
    doCheck = false;
  });

  mtgConfig = ''
    secret = "${config.sops.placeholder."moscow/mtg/secret"}"
    bind-to = "0.0.0.0:${toString bindPort}"
    prefer-ip = "prefer-ipv4"
    public-ipv4 = "46.8.21.129"

    [network]
    proxies = ["socks5://127.0.0.1:7891"]
  '';
in
{
  sops.templates."mtg.toml" = {
    content = mtgConfig;
    path = "/etc/mtg/config.toml";
    mode = "0600";
    restartUnits = [ "mtg.service" ];
  };

  systemd.services.mtg = {
    description = "MTProto proxy for Telegram";
    after = [ "network-online.target" "mihomo.service" ];
    wants = [ "network-online.target" "mihomo.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${mtg}/bin/mtg run \${CREDENTIALS_DIRECTORY}/config.toml";
      LoadCredential = "config.toml:/etc/mtg/config.toml";
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ bindPort ];
}
