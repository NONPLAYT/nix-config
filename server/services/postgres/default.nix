{ lib, ... }:

{
  services.postgresql = {
    enable = true;
    settings = {
      listen_addresses = "localhost";
    };
    ensureDatabases = [ "bx-team" ];
    # Allow password auth over TCP from localhost
    authentication = lib.mkAfter ''
      host all all 127.0.0.1/32 scram-sha-256
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    compression = "zstd";
    compressionLevel = 6;
    location = "/var/backup/postgresql";
  };
}
