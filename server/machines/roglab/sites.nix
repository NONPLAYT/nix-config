{ config, pkgs, lib, inputs, ... }:

let
  root = "/var/lib/sites";

  node = lib.getExe pkgs.nodejs_22;
  bun = lib.getExe pkgs.bun;

  sites = {
    roglab = {
      repo = "BX-Team/roglab";
      branch = "master";
      port = 3001;
      domains = [ "roglab.ru" ];
      build = "bun install && bun run build";
      start = "${node} .output/server/index.mjs";
      postgres = true;
      secret = true;
    };

    prikazy = {
      repo = "BX-Team/prikazy";
      branch = "main";
      port = 3002;
      domains = [ "prikazy.roglab.ru" ];
      build = "bun install && bun run build";
      start = "${node} node_modules/tsx/dist/cli.mjs server.ts";
      data = true;
    };

    kadet = {
      repo = "BX-Team/kadet";
      branch = "main";
      port = 3003;
      domains = [ "kadet.roglab.ru" ];
      build = "bun install && bun run build";
      start = "${node} node_modules/tsx/dist/cli.mjs server.ts";
      data = true;
      secret = true;
      env = {
        SQLITE_DB_PATH = "${root}/kadet/data/cadet_journal_v2.sqlite";
        TZ = "Europe/Moscow";
      };
    };

    app-backend = {
      repo = "BX-Team/app-backend";
      branch = "main";
      port = 3004;
      domains = [ "server.roglab.ru" ];
      build = "bun install --production --frozen-lockfile";
      start = "${bun} src/index.ts";
      postgres = true;
      secret = true;
    };

    app-frontend = {
      repo = "BX-Team/app-frontend";
      branch = "main";
      domains = [ "app.roglab.ru" ];
      build = "bun install && bun run build";
      static = "dist";
      locations."/api/".proxyPass = "http://127.0.0.1:${toString sites.app-backend.port}";
    };
  };

  databases = [ "roglab" "prikazy" "kadet" "app-backend" ];

  site = name: s: {
    postgres = false;
    data = false;
    secret = false;
    static = null;
    env = { };
    locations = { };
  } // s // { inherit name; dir = "${root}/${name}"; };

  all = lib.mapAttrsToList site sites;
  served = lib.filter (s: s.static == null) all;

  nativeLibs = lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ];

  gitCredentials = config.sops.templates."sites-git-credentials".path;

  hardening = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    ProtectSystem = "strict";
    ProtectHome = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictNamespaces = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
  };

  deploy = s: pkgs.writeShellApplication {
    name = "site-${s.name}-deploy";
    runtimeInputs = [ pkgs.git pkgs.gnutar pkgs.coreutils pkgs.findutils pkgs.util-linux pkgs.bun pkgs.nodejs_22 ];
    text = ''
      cd ${s.dir}
      [ -d repo ] || git init --quiet --bare repo

      git -C repo fetch --quiet --depth=1 https://github.com/${s.repo}.git ${s.branch}
      rev="$(git -C repo rev-parse FETCH_HEAD)"

      if [ "$(readlink current || true)" = "releases/$rev" ]; then
        exit 0
      fi
      # A broken commit is built once, not every few minutes until the next push.
      if [ "$(cat failed 2>/dev/null || true)" = "$rev" ]; then
        exit 0
      fi

      # Two builds at once do not fit in this box's memory.
      exec 9</run/sites-build.lock
      flock 9

      echo "building ${s.repo}@$rev"
      release="releases/$rev"
      rm -rf "$release"
      mkdir -p "$release"
      git -C repo archive "$rev" | tar -x -C "$release"

      if ! (cd "$release" && ${s.build}); then
        echo "$rev" > failed
        rm -rf "$release"
        echo "build of $rev failed, keeping the running release" >&2
        exit 1
      fi
      ${lib.optionalString s.data ''
        mkdir -p data
        rm -rf "$release/data"
        ln -s ../../data "$release/data"
      ''}
      ln -sfn "$release" current.new
      mv -T current.new current
      rm -f failed
      touch restart

      find releases -mindepth 1 -maxdepth 1 -printf '%T@ %p\n' | sort -rn | tail -n +4 | cut -d' ' -f2- |
        xargs -r rm -rf
      git -C repo gc --quiet --prune=now
    '';
  };

  restart = s: pkgs.writeShellScript "site-${s.name}-restart" ''
    if [ -e ${s.dir}/restart ]; then
      rm -f ${s.dir}/restart
      ${lib.optionalString (s.static == null) "${pkgs.systemd}/bin/systemctl restart site-${s.name}.service"}
    fi
  '';

  secretOf = s: config.sops.secrets."roglab/sites/${s.name}/env".path;

  pgEnv = s: lib.optionalAttrs s.postgres {
    DATABASE_URL = "postgresql:///${s.name}";
    PGHOST = "/run/postgresql";
    PGUSER = s.name;
    PGDATABASE = s.name;
  };
in
{
  imports = [ inputs.simple-nixos-mailserver.nixosModules.default ];

  # ---------------------------------------------------------------- postgres

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    ensureDatabases = databases;
    ensureUsers = map (name: { inherit name; ensureDBOwnership = true; }) databases;
  };

  services.postgresqlBackup = {
    enable = true;
    inherit databases;
    compression = "zstd";
    startAt = "*-*-* 04:00:00";
  };

  # ------------------------------------------------------------------- sites

  users.groups = lib.genAttrs (lib.attrNames sites) (_: { }) // { sites-git = { }; };
  users.users = lib.genAttrs (lib.attrNames sites)
    (name: {
      isSystemUser = true;
      group = name;
      home = "${root}/${name}";
    }) // {
    nginx.extraGroups = map (s: s.name) (lib.filter (s: s.static != null) all);
  };

  sops.templates."sites-git-credentials" = {
    owner = "root";
    group = "sites-git";
    mode = "0440";
    content = "https://nonplay:${config.sops.placeholder.github-token}@github.com\n";
  };

  sops.secrets = lib.listToAttrs (map
    (s: lib.nameValuePair "roglab/sites/${s.name}/env" {
      restartUnits = [ "site-${s.name}.service" ];
    })
    (lib.filter (s: s.secret) all));

  systemd.tmpfiles.rules = [ "f /run/sites-build.lock 0444 root root -" ];

  programs.nix-ld.enable = true;

  systemd.services = lib.mkMerge [
    (lib.listToAttrs (map
      (s: lib.nameValuePair "site-${s.name}-deploy" {
        description = "Build and roll out ${s.repo}";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" "sops-install-secrets.service" ];
        environment = {
          HOME = s.dir;
          LD_LIBRARY_PATH = nativeLibs;
          GIT_CONFIG_COUNT = "1";
          GIT_CONFIG_KEY_0 = "credential.helper";
          GIT_CONFIG_VALUE_0 = "store --file=${gitCredentials}";
        } // pgEnv s;
        serviceConfig = hardening // {
          Type = "oneshot";
          User = s.name;
          Group = s.name;
          SupplementaryGroups = [ "sites-git" ];
          StateDirectory = "sites/${s.name}";
          StateDirectoryMode = "0750";
          ExecStart = lib.getExe (deploy s);
          ExecStartPost = "+${restart s}";
          Nice = 10;
          TimeoutStartSec = "30min";
        };
      })
      all))

    (lib.listToAttrs (map
      (s: lib.nameValuePair "site-${s.name}" {
        description = "${s.repo}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ] ++ lib.optional s.postgres "postgresql.service";
        requires = lib.optional s.postgres "postgresql.service";
        unitConfig.ConditionPathExists = "${s.dir}/current";
        environment = {
          NODE_ENV = "production";
          HOME = s.dir;
          HOST = "127.0.0.1";
          PORT = toString s.port;
          LD_LIBRARY_PATH = nativeLibs;
        } // pgEnv s // s.env;
        serviceConfig = hardening // {
          User = s.name;
          Group = s.name;
          StateDirectory = "sites/${s.name}";
          StateDirectoryMode = "0750";
          WorkingDirectory = "${s.dir}/current";
          ExecStart = s.start;
          EnvironmentFile = lib.optional s.secret (secretOf s);
          Restart = "on-failure";
          RestartSec = 5;
        };
      })
      served))

    {
      roglab-cron = {
        description = "roglab status cron";
        unitConfig.ConditionPathExists = "${root}/roglab/current";
        serviceConfig = hardening // {
          Type = "oneshot";
          DynamicUser = true;
          EnvironmentFile = secretOf (site "roglab" sites.roglab);
          ExecStart = lib.getExe (pkgs.writeShellApplication {
            name = "roglab-cron";
            runtimeInputs = [ pkgs.curl ];
            text = ''
              curl -fsS -o /dev/null -H "Authorization: Bearer $NUXT_CRON_SECRET" \
                http://127.0.0.1:${toString sites.roglab.port}/api/cron/update-statuses
            '';
          });
        };
      };
    }
  ];

  systemd.timers = lib.listToAttrs
    (map
      (s: lib.nameValuePair "site-${s.name}-deploy" {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitInactiveSec = "3min";
        };
      })
      all) // {
    roglab-cron = {
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = "*:0/5";
    };
  };

  services.nginx.virtualHosts = lib.mkMerge (map
    (s: lib.genAttrs s.domains (_: {
      enableACME = true;
      forceSSL = true;
      locations =
        (if s.static != null then {
          "/" = {
            root = "${s.dir}/current/${s.static}";
            tryFiles = "$uri $uri/ /index.html";
          };
        } else {
          "/" = {
            proxyPass = "http://127.0.0.1:${toString s.port}";
            proxyWebsockets = true;
          };
        }) // s.locations;
    }))
    all);

  # -------------------------------------------------------------------- mail

  mailserver = {
    enable = true;
    stateVersion = 5;

    fqdn = "mail.roglab.ru";
    domains = [ "roglab.ru" ];
    systemContact = "postmaster@roglab.ru";

    localDnsResolver = false;

    accounts."support@roglab.ru" = {
      hashedPasswordFile = config.sops.secrets."roglab/mail/hash".path;
      aliases = [
        "abuse@roglab.ru" # RFC 2142
        "security@roglab.ru" # RFC 2142
        "postmaster@roglab.ru" # RFC 5321
      ];

      sieveScript = ''
        require [ "fileinto", "mailbox" ];

        if header :is "X-Spam" "Yes" {
          fileinto "Junk";
          stop;
        }

        if address :is [ "to", "cc" ] [
          "abuse@roglab.ru",
          "security@roglab.ru",
          "postmaster@roglab.ru"
        ] {
          fileinto :create "Admin";
          stop;
        }
      '';
    };

    x509.useACMEHost = "mail.roglab.ru";
  };

  services.postfix.settings.main = {
    relayhost = [ "[smtp.mail.selcloud.ru]:1127" ];
    smtp_tls_wrappermode = "yes";
    smtp_tls_security_level = lib.mkForce "encrypt";
    smtp_sasl_auth_enable = "yes";
    smtp_sasl_password_maps = "texthash:${config.sops.templates."postfix-relay".path}";
    smtp_sasl_security_options = "noanonymous";
    smtp_sasl_tls_security_options = "noanonymous";
  };

  sops.templates."postfix-relay" = {
    mode = "0400";
    restartUnits = [ "postfix.service" ];
    content = "[smtp.mail.selcloud.ru]:1127 13856:${config.sops.placeholder."roglab/mail/relay-password"}\n";
  };

  services.rspamd.overrides."greylist.conf".text = "enabled = false;";

  services.roundcube = {
    enable = true;
    hostName = "mail.roglab.ru";
    maxAttachmentSize = 25;
    dicts = with pkgs.aspellDicts; [ en ru ];
    extraConfig = ''
      $config['imap_host'] = "ssl://mail.roglab.ru:993";
      $config['smtp_host'] = "ssl://mail.roglab.ru:465";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
  };
}
