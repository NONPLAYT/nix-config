{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
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
    enableIPv6 = true;
    defaultGateway = "207.2.123.1";
    interfaces.eth0 = {
      ipv4.addresses = [
        { address = "207.2.123.110"; prefixLength = 24; }
      ];
      ipv6.addresses = [
        { address = "2a13:7c81:fff::1b7"; prefixLength = 128; }
      ];
      ipv6.routes = [
        { address = "2a13:7c81::1"; prefixLength = 128; }
        { address = "::"; prefixLength = 0; via = "2a13:7c81::1"; }
      ];
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  time.timeZone = "Europe/Stockholm";
}
