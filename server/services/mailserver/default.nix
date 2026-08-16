{ config
, pkgs
, lib
, inputs
, ...
}:

{
  imports = [ inputs.simple-nixos-mailserver.nixosModules.default ];

  mailserver = {
    enable = true;
    stateVersion = 5;

    fqdn = "mail.bxteam.org";
    domains = [ "bxteam.org" ];
    systemContact = "postmaster@bxteam.org";

    localDnsResolver = false;

    accounts."mail@bxteam.org" = {
      hashedPasswordFile = config.sops.secrets."stockholm/mail/hash".path;
      aliases = [
        "nonplay@bxteam.org"
        "admin@bxteam.org"
        "contact@bxteam.org"
        "support@bxteam.org"
        "abuse@bxteam.org" # RFC 2142
        "security@bxteam.org" # RFC 2142
        "postmaster@bxteam.org" # RFC 5321
      ];

      sieveScript = ''
        require [ "fileinto", "mailbox" ];

        if header :is "X-Spam" "Yes" {
          fileinto "Junk";
          stop;
        }

        if address :is [ "to", "cc" ] [
          "admin@bxteam.org",
          "abuse@bxteam.org",
          "security@bxteam.org",
          "postmaster@bxteam.org"
        ] {
          fileinto :create "Admin";
          stop;
        }

        if address :is [ "to", "cc" ] [
          "contact@bxteam.org",
          "support@bxteam.org"
        ] {
          fileinto :create "Support";
          stop;
        }
      '';
    };

    x509.useACMEHost = "mail.bxteam.org";
  };

  services.postfix.settings.main = {
    relayhost = [ "[relay.hostup.se]:587" ];
    smtp_tls_security_level = lib.mkForce "encrypt";
  };

  services.rspamd.overrides."greylist.conf".text = "enabled = false;";

  services.roundcube = {
    enable = true;
    hostName = "mail.bxteam.org";
    maxAttachmentSize = 25;
    dicts = with pkgs.aspellDicts; [ en ru ];
    extraConfig = ''
      $config['imap_host'] = "ssl://mail.bxteam.org:993";
      $config['smtp_host'] = "ssl://mail.bxteam.org:465";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };
}
