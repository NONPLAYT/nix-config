{ config, lib, isServer, ... }:

let
  parseSopsKeys =
    file:
    let
      lines = lib.splitString "\n" (builtins.readFile file);
      keyOf = line: let m = builtins.match " *([^:]+):.*" line; in if m == null then null else builtins.head m;
      indentOf = line: builtins.stringLength (builtins.head (builtins.match "( *).*" line));
      hasEnc = line: builtins.match ".*ENC\\[.*" line != null;
      res = builtins.foldl'
        (acc: line:
          let
            k = keyOf line;
            ind = indentOf line;
          in
          if acc.done then acc
          else if k == null then acc
          else if k == "sops" && ind == 0 then acc // { done = true; }
          else
            let
              # drop ancestors at the same or deeper indent — siblings/closed scopes
              kept = builtins.filter (e: e.indent < ind) acc.stack;
              prefix = builtins.concatStringsSep "/" (map (e: e.key) kept);
              fullName = if prefix == "" then k else "${prefix}/${k}";
            in
            if hasEnc line then
              acc // { stack = kept; names = acc.names ++ [ fullName ]; }
            else
              acc // { stack = kept ++ [ { indent = ind; key = k; } ]; }
        )
        { stack = [ ]; names = [ ]; done = false; }
        lines;
    in
    res.names;

  secretOverrides = {
    "pg-node/ssl_cert" = { path = "${pgCertDir}/ssl_cert.pem"; mode = "0600"; };
    "pg-node/ssl_key" = { path = "${pgCertDir}/ssl_key.pem"; mode = "0600"; };
  };

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

    secrets = lib.genAttrs (parseSopsKeys ./secrets.yaml) (
      name: secretOverrides.${name} or { }
    );

    templates = lib.mkMerge [
      {
      "caddy.env".content = ''
        CF_API_TOKEN=${config.sops.placeholder.cloudflare}
      '';

      "influx.env".content = ''
        DATABASE_URL=${config.sops.placeholder."stockholm/influx/database-url"}
        REDIS_URL=redis://127.0.0.1:6379
        PORT=${toString influxPort}
        HOST=0.0.0.0
      '';

      "cinder.env".content = ''
        DATABASE_URL=${config.sops.placeholder."stockholm/cinder/database-url"}
        REDIS_URL=redis://127.0.0.1:6379
        CLICKHOUSE_URL=${config.sops.placeholder."stockholm/cinder/clickhouse-url"}
        GEOIP_DB_PATH=/var/lib/geoip/GeoLite2-Country.mmdb
      '';

      "geoip.env".content = ''
        GEOIPUPDATE_ACCOUNT_ID=${config.sops.placeholder."stockholm/geoip/account-id"}
        GEOIPUPDATE_LICENSE_KEY=${config.sops.placeholder."stockholm/geoip/license-key"}
      '';

      "meridian.env".content = ''
        DATABASE_URL=${config.sops.placeholder."stockholm/meridian/database-url"}
        CLICKHOUSE_URL=${config.sops.placeholder."stockholm/meridian/clickhouse-url"}
        GITHUB_TOKEN=${config.sops.placeholder.github-token}
        BETTER_AUTH_SECRET=${config.sops.placeholder."stockholm/meridian/better-auth-secret"}
        BETTER_AUTH_URL=https://bxteam.org
        RESEND_API_KEY=${config.sops.placeholder."stockholm/meridian/resend-api-key"}
        RESEND_MAGIC_LINK_TEMPLATE_ID="magic-link"
        GITHUB_CLIENT_ID=Ov23liKrjDcQvLbkmolD
        GITHUB_CLIENT_SECRET=${config.sops.placeholder."stockholm/meridian/github-client-secret"}
        DISCORD_CLIENT_ID=1014467419181436928
        DISCORD_CLIENT_SECRET=${config.sops.placeholder."stockholm/meridian/discord-client-secret"}
        NUXT_API_SECRET_KEY=${config.sops.placeholder."stockholm/meridian/nuxt-api-secret-key"}
        NUXT_R2_PUBLIC_URL=https://files.bxteam.org
        NUXT_R2_ACCESS_KEY_ID=${config.sops.placeholder."stockholm/meridian/r2-access-key-id"}
        NUXT_R2_SECRET_ACCESS_KEY=${config.sops.placeholder."stockholm/meridian/r2-secret-access-key"}
        NUXT_R2_ENDPOINT=https://6c19bad5e3a3ea0820bb7b1fa745e6c2.r2.cloudflarestorage.com
        NUXT_R2_BUCKET=builds
        PORT=${toString meridianPort}
        HOST=0.0.0.0
      '';

      "frps.toml".content = ''
        bindPort = ${toString frpBindPort}
        vhostHTTPPort = ${toString frpVhostPort}

        auth.method = "token"
        auth.token = "${config.sops.placeholder."stockholm/frp/token"}"
      '';

      "pg-node.env".content = ''
        SERVICE_PORT=${toString pgServicePort}
        NODE_HOST=0.0.0.0
        SERVICE_PROTOCOL=grpc
        PG_NODE_WG_HOST_ROUTING=1
        SSL_CERT_FILE=${pgCertDir}/ssl_cert.pem
        SSL_KEY_FILE=${pgCertDir}/ssl_key.pem
        GENERATED_CONFIG_PATH=/var/lib/pg-node/generated
        API_KEY=${config.sops.placeholder."stockholm/pg-node/api-key"}
      '';
      }

      (lib.mkIf isServer {
        "git-credentials" = {
          owner = "root";
          mode = "0600";
          path = "/root/.git-credentials";
          content = "https://nonplay:${config.sops.placeholder.github-token}@github.com";
        };
      })
      (lib.mkIf (!isServer) {
        "git-creds-nonplay" = {
          owner = "nonplay";
          mode = "0600";
          path = "/home/nonplay/.git-credentials";
          content = "https://nonplay:${config.sops.placeholder.github-token}@github.com";
        };
      })
    ];
  };
}
