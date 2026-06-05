{ lib, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    settings = {
      listen_addresses = lib.mkForce "*";
    };
    ensureDatabases = [ "bx-team" ];
    # Allow password auth over TCP from localhost
    authentication = lib.mkAfter ''
      host all all 127.0.0.1/32 scram-sha-256
      host all all 0.0.0.0/0 scram-sha-256
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
