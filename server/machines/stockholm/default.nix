{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../services/cloudflared
    ../../services/mailserver
    ../../services/kura
    ../../services/nginx
    ../../services/reposilite
    ../../services/rfc-bot
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  networking = {
    hostName = "stockholm";
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
}
