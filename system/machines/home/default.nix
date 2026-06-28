{ config
, pkgs
, inputs
, ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.hardware.nixosModules.common-cpu-amd

    ../../services/flatpak
    ../../services/mihomo
    ../../services/printing
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [
      pkgs.linuxPackages_latest.v4l2loopback
    ];

    kernelParams = [ "nvidia-drm.fbdev=1" ];
    kernelModules = [ "tun" "v4l2loopback" ];

    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=0 card_label="OBS Virtual Camera" exclusive_caps=1
    '';

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
      maxGenerations = 3;
      secureBoot.enable = true;
      extraEntries = ''
        /Windows 11
          protocol: efi
          path: guid(ee7a92b1-a072-461a-ac7d-7816643be29f):/EFI/Microsoft/Boot/bootmgfw.efi
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

  networking = {
    hostName = "home";
    domain = "bxteam.org";
    useDHCP = false;

    networkmanager.enable = true;
  };

  home-manager.users.nonplay.xdg.configFile = {
    "niri/outputs.kdl".text = ''
      output "HDMI-A-1" {
          mode "1920x1080@60"
          scale 1.0
          transform "normal"
          position x=0 y=0
      }

      workspace "social" {
          open-on-output "HDMI-A-1"
      }
      workspace "media" {
          open-on-output "HDMI-A-1"
      }
    '';
  };

  systemd.services.NetworkManager-wait-online.serviceConfig = {
    ExecStart = [
      ""
      "${pkgs.networkmanager}/bin/nm-online -q --timeout=2"
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  programs.steam.gamescopeSession.args = [
    "-W"
    "1920"
    "-H"
    "1080"
    "-r"
    "60"
  ];

  system.stateVersion = "26.05";
}
