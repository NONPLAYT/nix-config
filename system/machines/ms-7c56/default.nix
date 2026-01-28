{ config, pkgs, lib, inputs, ... }:

{
  imports = [ 
    inputs.hardware.nixosModules.common-cpu-amd
    ./hardware-configuration.nix 
  ];

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_18;
    extraModulePackages = [ pkgs.linuxKernel.packages.linux_6_18.rtl8821cu ];

    kernelParams = [ "nvidia-drm.fbdev=1" ];

    initrd = {
      systemd.enable = true;
      verbose = true;
    };

    loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    loader.limine = {
      enable = true;
      enableEditor = true;
      maxGenerations = 3;
      secureBoot.enable = true;
      extraEntries = ''
        /Windows 11
          protocol: efi
          path: guid(c12a7328-f81f-11d2-ba4b-00a0c93ec93b):/EFI/Microsoft/Boot/bootmgfw.efi
      '';

      # Catppucin mocha style
      style.wallpapers = [ ];
      style.graphicalTerminal.palette = "1e1e2e;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4";
      style.graphicalTerminal.brightPalette = "585b70;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4";
      style.graphicalTerminal.background = "1e1e2e";
      style.graphicalTerminal.foreground = "cdd6f4";
      style.graphicalTerminal.brightBackground = "585b70";
      style.graphicalTerminal.brightForeground = "cdd6f4";
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ]; 
  };

  networking.hostName = "ms-7c56";
  system.stateVersion = "26.05";
}
