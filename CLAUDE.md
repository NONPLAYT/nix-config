# CLAUDE.md

NixOS flake driving my machines. Baseline shared by every host lives in `common/` (locale/timezone, nix settings, sshd + fail2ban, sysctl hardening, root-facing zsh/git/btop); the desktop is `desktop/` (user `nonplay`, home-manager, Niri), servers are `server/` (user `root`), home-manager lives in `home/`, package overlays in `overlays/`, sops store in `secrets/`. The authoritative host list is `nixosConfigurations` in `flake.nix` — read it there, never trust docs or memory for it.

## Hard rules

- Never build or apply configs (`nh os switch`, `nixos-rebuild`, `nix build` of a toplevel). I deploy myself. Never suggest `--target-host` / remote builds / pushing closures.
- Eval-only verification: `nix eval /etc/nixos#nixosConfigurations.<host>.config.system.build.toplevel.drvPath --raw`, or `nix flake check /etc/nixos` when touching shared files. `git add` new files first — flake eval ignores untracked files.
- Secrets never appear in `.nix` files — only sops placeholders/templates (`secrets/*.yaml`; `sops -d` works from my shell).
- Format `.nix` with `nixpkgs-fmt`.

## Mechanics

- `host`, `isServer`, `inputs` come via specialArgs; per-host gating via `lib.mkIf (host == "…")` or `isServer`.
- Flake module paths: `(base + "/path")`, never `"${base}/path"` — interpolation breaks relative imports inside modules.
- Anything in `common/` is evaluated by *both* the desktop and the servers. Options a machine overrides (`system.stateVersion`, `time.timeZone`) must be `lib.mkDefault` there; per-host additions to list options use `lib.mkAfter`.
- `secrets/default.nix` derives `sops.secrets` by *parsing the yaml itself* — every `ENC[...]` leaf becomes a secret named by its `path/to/key`. Adding a secret means editing the yaml only; touch `secretOverrides` there just for a non-default owner/mode. Scope: `secrets.yaml` for all hosts, `home.yaml` desktop-only, `<host>.yaml` per server.
- New sops host: `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub` → add to `secrets/.sops.yaml` → `cd secrets && sops updatekeys <file>.yaml` for every file that host must decrypt.
- `overlays/default.nix` is a single `final: prev:` attrset; each package gets its own file next to it and is wired in with `prev.callPackage ./<name>.nix { }`.
- Desktop services live in `desktop/services/<name>/` but are imported by `desktop/machines/<host>/default.nix`, not by `desktop/configuration.nix` — put host-specific services there.
- sshd listens on **2022** everywhere (`common/sshd.nix`); fail2ban jails that port. Servers must also open it in `networking.firewall.allowedTCPPorts`.
- `home/shared/programs.nix` returns a *list* of module paths plus one inline module — add new home-manager programs to that list.
- mihomo (`desktop/services/mihomo`) is rendered from a sops template — tell me to restart it manually when its config changed.
