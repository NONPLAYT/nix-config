{ config, lib, isServer, host, ... }:

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
              kept = builtins.filter (e: e.indent < ind) acc.stack;
              prefix = builtins.concatStringsSep "/" (map (e: e.key) kept);
              fullName = if prefix == "" then k else "${prefix}/${k}";
            in
            if hasEnc line then
              acc // { stack = kept; names = acc.names ++ [ fullName ]; }
            else
              acc // { stack = kept ++ [{ indent = ind; key = k; }]; }
        )
        { stack = [ ]; names = [ ]; done = false; }
        lines;
    in
    res.names;

  secretOverrides = {
    "home/ssh/key" = { owner = "nonplay"; mode = "0400"; };
  };
in
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    useSystemdActivation = true;
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ ];
    };

    secrets =
      let
        mkSecretsFor =
          file:
          if !builtins.pathExists file then
            { }
          else
            lib.genAttrs (parseSopsKeys file) (
              name: { sopsFile = file; } // (secretOverrides.${name} or { })
            );
      in
      lib.mkMerge [
        (mkSecretsFor ./secrets.yaml)
        (lib.mkIf (!isServer) (mkSecretsFor ./home.yaml))
        (lib.mkIf isServer (mkSecretsFor (./. + "/${host}.yaml")))
      ];

    templates = lib.mkMerge [
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
