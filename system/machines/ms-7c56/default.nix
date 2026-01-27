{ config, pkgs, lib, inputs, ... }:

{
  imports = [ 
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.lanzaboote.nixosModules.lanzaboote
    ./hardware-configuration.nix 
  ];

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_18;
    extraModulePackages = pkgs.linuxKernel.packages.linux_6_18.rtl8821cu;

    kernelParams = [ "nvidia-drm.modeset=1" ];

    initrd = {
      systemd.enable = true;
      verbose = true;
    };

    loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    loader.systemd-boot = {
      enable = lib.mkForce false;
      configurationLimit = 3;
      consoleMode = "max";
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver.enable = true;
  services.xserver.videoDriver = "modesetting";

  networking.hostName = "ms-7c56";
  system.stateVersion = "26.05";
}
