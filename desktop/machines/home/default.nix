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
    ../../services/kura-runner
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

      # https://github.com/noctalia-dev/community-palettes/tree/main/Mizuki-Akiyama
      style = {
        wallpapers = [ ];

        interface = {
          brandingColor = "e6a6c8"; # mPrimary
          helpColor = "c8b9ca"; # mOnSurfaceVariant
          helpColorBright = "afa2d8"; # mSecondary, used for the countdown digit
        };

        graphicalTerminal = {
          #          black ;  red  ; green ;yellow;  blue ;magenta; cyan ; white
          palette = "1d1a2a;f08a9b;8fd0b8;d9b874;7fb6d6;d8a2cb;7cced9;eee7f0";
          brightPalette = "4d465c;ff9caf;a7dec9;efd08d;9dcee7;e6b6d5;9adde4;ffffff";

          foreground = "eee7f0"; # mOnSurface
          brightForeground = "ffffff";
          background = "4010111b"; # mSurface
          brightBackground = "1d1a2a"; # mSurfaceVariant

          margin = 64;
          marginGradient = 24;
        };
      };
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

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      Experimental = true;
      FastConnectable = true;
    };
  };

  services.blueman.enable = true;

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
    nvidiaSettings = true;
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
