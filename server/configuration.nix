{ pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../common
    ../secrets
    ../proxy
  ];

  services.qemuGuest.enable = true;

  networking = {
    domain = "bxteam.org";
    enableIPv6 = lib.mkDefault false;
    firewall.enable = lib.mkDefault true;
    firewall.allowedTCPPorts = [ 2022 ];
    dhcpcd.enable = lib.mkDefault false;
  };

  zramSwap.enable = true;
  boot.kernel.sysctl."net.core.netdev_max_backlog" = 5000;

  programs.ssh.extraConfig = ''
    Host *
      ForwardAgent no
      AddKeysToAgent 30m
      Compression no
      ServerAliveInterval 0
      ServerAliveCountMax 3
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no
      IdentityFile ~/.ssh/multi.key
  '';

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
  };
}
