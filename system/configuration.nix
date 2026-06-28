{ pkgs
, lib
, inputs
, host
, ...
}:

{
  networking = {
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    enableIPv6 = lib.mkDefault false;
    networkmanager.dns = "none";
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "ru_RU.UTF-8";
      LC_NUMERIC = "ru_RU.UTF-8";
      LC_MONETARY = "ru_RU.UTF-8";
      LC_MEASUREMENT = "ru_RU.UTF-8";
      LC_PAPER = "ru_RU.UTF-8";
    };
  };

  time.timeZone = "Europe/Moscow";

  imports = [
    ./services/greetd
    ./services/pipewire
    ./services/ssh
  ];

  programs = {
    zsh.enable = true;
    dconf.enable = true;
    gamemode.enable = true;
    nix-ld.enable = true;
    nix-index-database.comma.enable = true;
    niri.enable = true;
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraArgs = "-cef-disable-gpu";
      };
      gamescopeSession.enable = true;
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };

  services = {
    libinput.enable = true;
    seatd.enable = true;
    blueman.enable = true;
    udisks2.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      sbctl
      curl
      git
      wget
      lm_sensors
      nettools
      kitty
      wl-clipboard
      usb-modeswitch
      xwayland-satellite
      libinput
      uxplay
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  console = {
    keyMap = "us";
  };

  users.users.nonplay = {
    isNormalUser = true;
    shell = pkgs.zsh;
    hashedPassword = "$y$j9T$SuNlLbWK7o/PibPPzl83M/$o3QpZXjLJGtd2N2JoFdCvWJ8agow8eGxOznzHJjq0K5";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "dialout"
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs host; };
    users.nonplay = import (../home/wm/niri);
  };

  security.pam.services = {
    greetd.enableGnomeKeyring = true;
    hyprlock.enableGnomeKeyring = true;
  };

  systemd.tmpfiles.rules = [
    "d /etc/nixos 0755 nonplay users - -"
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    settings = {
      auto-optimise-store = true;
      accept-flake-config = true;
      trusted-users = [
        "root"
        "nonplay"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      fallback = true;
      connect-timeout = 5;
      stalled-download-timeout = 30;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://noctalia.cachix.org"
        "https://zed.cachix.org"
        "https://bx-team.cachix.org"
        "https://cache.garnix.io"
        "https://ayugram-desktop.cachix.org"
        "https://wrangler.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
        "bx-team.cachix.org-1:tnGNc1rsS8QOav+VGxXCZzf/Y0/SGchOwVCCBA/eG6E="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "ayugram-desktop.cachix.org:AZ5EqHrJsAKL5YkZYLPEsb1FdD9QlypUwQ0REcJftgA="
        "wrangler.cachix.org-1:N/FIcG2qBQcolSpklb2IMDbsfjZKWg+ctxx0mSMXdSs="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "jetbrains.idea"
    "steam"
  ];
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-10.34.0"
  ];
}
