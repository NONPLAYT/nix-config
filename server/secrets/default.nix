{ config, ... }:

let
  # mtprotoproxy
  mtprotoPort = 8443;
  mtprotoUser = "tg";

  # frp
  frpBindPort = 6060;
  frpVhostPort = 6061;

  # pg-node
  pgServicePort = 62050;
  pgCertDir = "/var/lib/pg-node/certs";

  # meridian nuxt app
  meridianPort = 3000;

  # influx bun app
  influxPort = 3001;
in
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    useSystemdActivation = true;
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ ];
    };

    secrets = {
      "git-credentials" = {
        owner = "root";
        mode = "0600";
        path = "/root/.git-credentials";
      };
      "caddy/cf-token" = { };
      "mtproto/secret" = { };
      "frp/token" = { };
      "pg-node/api-key" = { };
      "pg-node/ssl_cert" = {
        path = "${pgCertDir}/ssl_cert.pem";
        mode = "0600";
      };
      "pg-node/ssl_key" = {
        path = "${pgCertDir}/ssl_key.pem";
        mode = "0600";
      };
      # meridian
      "meridian/database-url" = { };
      "meridian/clickhouse-url" = { };
      "meridian/github-token" = { };
      "meridian/better-auth-secret" = { };
      "meridian/resend-api-key" = { };
      "meridian/github-client-secret" = { };
      "meridian/discord-client-secret" = { };
      "meridian/nuxt-api-secret-key" = { };
      "meridian/r2-access-key-id" = { };
      "meridian/r2-secret-access-key" = { };
      # umami
      "umami/secret-key" = { };
      # influx bun app
      "influx/database-url" = { };
      # cinder bun worker
      "cinder/database-url" = { };
      "cinder/clickhouse-url" = { };
      # geoipupdate — MaxMind credentials
      "geoip/account-id" = { };
      "geoip/license-key" = { };
    };

    templates = {
      "caddy.env".content = ''
        CF_API_TOKEN=${config.sops.placeholder."caddy/cf-token"}
      '';

      "influx.env".content = ''
        DATABASE_URL=${config.sops.placeholder."influx/database-url"}
        REDIS_URL=redis://127.0.0.1:6379
        PORT=${toString influxPort}
        HOST=0.0.0.0
      '';

      "cinder.env".content = ''
        DATABASE_URL=${config.sops.placeholder."cinder/database-url"}
        REDIS_URL=redis://127.0.0.1:6379
        CLICKHOUSE_URL=${config.sops.placeholder."cinder/clickhouse-url"}
        GEOIP_DB_PATH=/var/lib/geoip/GeoLite2-Country.mmdb
      '';

      "geoip.env".content = ''
        GEOIPUPDATE_ACCOUNT_ID=${config.sops.placeholder."geoip/account-id"}
        GEOIPUPDATE_LICENSE_KEY=${config.sops.placeholder."geoip/license-key"}
      '';

      "meridian.env".content = ''
        DATABASE_URL=${config.sops.placeholder."meridian/database-url"}
        CLICKHOUSE_URL=${config.sops.placeholder."meridian/clickhouse-url"}
        GITHUB_TOKEN=${config.sops.placeholder."meridian/github-token"}
        BETTER_AUTH_SECRET=${config.sops.placeholder."meridian/better-auth-secret"}
        BETTER_AUTH_URL=https://bxteam.org
        RESEND_API_KEY=${config.sops.placeholder."meridian/resend-api-key"}
        RESEND_MAGIC_LINK_TEMPLATE_ID="magic-link"
        GITHUB_CLIENT_ID=Ov23liKrjDcQvLbkmolD
        GITHUB_CLIENT_SECRET=${config.sops.placeholder."meridian/github-client-secret"}
        DISCORD_CLIENT_ID=1014467419181436928
        DISCORD_CLIENT_SECRET=${config.sops.placeholder."meridian/discord-client-secret"}
        NUXT_API_SECRET_KEY=${config.sops.placeholder."meridian/nuxt-api-secret-key"}
        NUXT_R2_PUBLIC_URL=https://files.bxteam.org
        NUXT_R2_ACCESS_KEY_ID=${config.sops.placeholder."meridian/r2-access-key-id"}
        NUXT_R2_SECRET_ACCESS_KEY=${config.sops.placeholder."meridian/r2-secret-access-key"}
        NUXT_R2_ENDPOINT=https://6c19bad5e3a3ea0820bb7b1fa745e6c2.r2.cloudflarestorage.com
        NUXT_R2_BUCKET=builds
        PORT=${toString meridianPort}
        HOST=0.0.0.0
      '';

      "frps.toml".content = ''
        bindPort = ${toString frpBindPort}
        vhostHTTPPort = ${toString frpVhostPort}

        auth.method = "token"
        auth.token = "${config.sops.placeholder."frp/token"}"
      '';

      "pg-node.env".content = ''
        SERVICE_PORT=${toString pgServicePort}
        NODE_HOST=0.0.0.0
        SERVICE_PROTOCOL=grpc
        PG_NODE_WG_HOST_ROUTING=1
        SSL_CERT_FILE=${pgCertDir}/ssl_cert.pem
        SSL_KEY_FILE=${pgCertDir}/ssl_key.pem
        GENERATED_CONFIG_PATH=/var/lib/pg-node/generated
        API_KEY=${config.sops.placeholder."pg-node/api-key"}
      '';
    };
  };
}
