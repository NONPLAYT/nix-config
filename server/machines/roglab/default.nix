{ pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./sites.nix

    ../../services/nginx
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  networking = {
    hostName = "roglab";
    domain = lib.mkForce "roglab.ru";
    enableIPv6 = false;
    usePredictableInterfaceNames = false;
    interfaces.eth0.ipv4.addresses = [{ address = "135.106.192.252"; prefixLength = 24; }];
    defaultGateway = { address = "135.106.192.1"; interface = "eth0"; };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "77.88.8.8"
    ];
  };

  swapDevices = [{ device = "/var/lib/swapfile"; size = 4 * 1024; }];

  security.acme.defaults.email = lib.mkForce "postmaster@roglab.ru";

  time.timeZone = "Europe/Moscow";
}
