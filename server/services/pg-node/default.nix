{ config, ... }:

{
  # wireguard host routing in the image needs the kernel module
  boot.kernelModules = [ "wireguard" ];

  systemd.tmpfiles.rules = [
    "d /var/lib/pg-node 0700 root root -"
    "d /var/lib/pg-node/certs 0700 root root -"
  ];

  systemd.services."docker-pg-node" = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };

  virtualisation.oci-containers.containers.pg-node = {
    image = "pasarguard/node:latest";
    environmentFiles = [ config.sops.templates."pg-node.env".path ];
    extraOptions = [
      "--network=host"
      "--privileged"
      "--cap-add=NET_ADMIN"
    ];
    volumes = [
      "/var/lib/pg-node:/var/lib/pg-node"
      "${config.sops.secrets."stockholm/pg-node/ssl_cert".path}:${config.sops.secrets."stockholm/pg-node/ssl_cert".path}:ro"
      "${config.sops.secrets."stockholm/pg-node/ssl_key".path}:${config.sops.secrets."stockholm/pg-node/ssl_key".path}:ro"
    ];
  };
}
