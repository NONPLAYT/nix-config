{
  pkgs,
  lib,
  inputs,
  host,
  ...
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
  };

  services = {
    libinput.enable = true;
    seatd.enable = true;
    blueman.enable = true;
    flatpak.enable = true;
    udisks2.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      sbctl
      micro
      curl
      git
      wget
      lm_sensors
      nettools
      kitty
      wl-clipboard
      usb-modeswitch
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
      trusted-users = [
        "root"
        "nonplay"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://noctalia.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "jetbrains.idea"
  ];
}
