{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../services/nginx
    ../../services/xray
    ../../services/mihomo
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.grub = {
      enable = true;
      device = "/dev/vda";
    };
  };

  networking = {
    hostName = "moscow";
    enableIPv6 = false;
    defaultGateway = "46.8.21.1";
    interfaces.ens3 = {
      ipv4.addresses = [
        { address = "46.8.21.129"; prefixLength = 24; }
      ];
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "77.88.8.8"
    ];
  };

  time.timeZone = "Europe/Moscow";
}
