{ pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../services/nginx
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  systemd.generators.systemd-gpt-auto-generator = "/dev/null";

  networking = {
    hostName = "asgard";
    enableIPv6 = false;
    dhcpcd = {
      enable = true;
      extraConfig = "nooption domain_name_servers";
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  time.timeZone = "Europe/Stockholm";

  users.users.root.openssh.authorizedKeys.keys = lib.mkAfter [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKGvxxKIkxf7R7XYY0wmTbIgtGJ5zh5T8tmbo1Rv1LXc eblan@asgard"
  ];

  services.nginx.virtualHosts."asgard.bxteam.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      index = "index.html";
      root = pkgs.writeTextDir "index.html" ''
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>asgard.bxteam.org</title>
        </head>
        <body></body>
        </html>
      '';
    };
  };
}
