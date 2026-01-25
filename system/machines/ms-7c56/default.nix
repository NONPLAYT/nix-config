{ pkgs, inputs, ... }:

{
  imports = [ 
    inputs.hardware.nixosModules.common-cpu-amd
    ./hardware-configuration.nix 
  ];

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_18;

    loader.efi = {
      canTouchEfiVariables = false;
    };

    loader.grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = false;
      efiInstallAsRemovable = true;
    };
  };

  networking.hostName = "ms-7c56";
  system.stateVersion = "26.05";
}
