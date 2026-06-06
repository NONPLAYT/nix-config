{ pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../secrets
    ./programs/git
    ./programs/ssh
    ./programs/zsh
    ./programs/btop
    ./services/sshd
    ./services/docker
    ./services/frp
    ./services/mtprotoproxy
    ./services/pg-node
    ./services/caddy
    ./services/postgres
    ./services/redis
    ./services/clickhouse
    ./services/meridian
    ./services/influx
    ./services/cinder
    ./services/geoipupdate
    ./services/reposilite
    ./services/umami
  ];

  services.qemuGuest.enable = true;

  networking = {
    domain = "bxteam.org";
    enableIPv6 = lib.mkDefault false;
    firewall.enable = lib.mkDefault false;
    dhcpcd.enable = lib.mkDefault false;
  };

  zramSwap.enable = true;
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.tcp_max_syn_backlog" = 4096;
    "net.core.somaxconn" = 4096;
    "net.core.netdev_max_backlog" = 5000;
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

  environment = {
    systemPackages = with pkgs; [
      curl
      wget
      gh
      dig
      eza
      age
      sops
      mtr
      jq
      file
      nitch
    ];

    variables = {
      EDITOR = "nano";
      VISUAL = "nano";
      GIT_ASKPASS = "";
    };
  };

  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
  };

  console.keyMap = "us";

  users.users.root = {
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2y5ojFwo0p78rZgc3S31h7CyIdCyWOO9xcajs51m7F bxteam.org"
    ];
  };
  services.getty.autologinUser = "root";
  security.pam.services.login.rules.session.lastlog.enable = lib.mkForce false;

  nix = {
    channel.enable = false;
    nixPath = [ "nixpkgs=flake:nixpkgs" ];

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    settings = {
      auto-optimise-store = true;
      trusted-users = [
        "root"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";
}
