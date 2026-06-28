{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    ../../services/nginx
    ../../services/reposilite
    ../../services/xray
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      timeout = 0;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
        timeoutStyle = "countdown";
        extraConfig = ''
          serial --unit=0 --speed=115200
          terminal_input serial console
          terminal_output serial console
        '';
      };
      efi.efiSysMountPoint = "/boot/efi";
    };
    kernelParams = [ "console=tty1" "console=ttyS0,115200n8" ];
  };

  networking = {
    hostName = "finland";
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

  time.timeZone = "Europe/Helsinki";
}
