{ pkgs
, lib
, inputs
, host
, ...
}:

{
  imports = [
    ../common
    ./services/greetd
    ./services/pipewire
  ];

  networking = {
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    enableIPv6 = lib.mkDefault false;
    networkmanager.dns = "none";
  };

  programs = {
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
    udisks2.enable = true;
    gvfs.enable = true;
    gnome.gnome-keyring.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      sbctl
      curl
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
      "lp"
      "scanner"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2y5ojFwo0p78rZgc3S31h7CyIdCyWOO9xcajs51m7F bxteam.org"
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

  nix.settings = {
    trusted-users = lib.mkAfter [ "nonplay" ];
    fallback = true;
    connect-timeout = 5;
    stalled-download-timeout = 30;
    substituters = lib.mkAfter [
      "https://noctalia.cachix.org"
      "https://zed.cachix.org"
      "https://wrangler.cachix.org"
    ];
    trusted-public-keys = lib.mkAfter [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "wrangler.cachix.org-1:N/FIcG2qBQcolSpklb2IMDbsfjZKWg+ctxx0mSMXdSs="
    ];
  };

  nixpkgs.overlays = [
    (self: super: {
      libdisplay-info = super.libdisplay-info.overrideAttrs {
        version = "0.3.0";
        src = super.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "emersion";
          repo = "libdisplay-info";
          rev = "0.3.0";
          sha256 = "sha256-nXf2KGovNKvcchlHlzKBkAOeySMJXgxMpbi5z9gLrdc=";
        };
      };
    })
  ];
}
