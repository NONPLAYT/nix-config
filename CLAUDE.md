# CLAUDE.md

NixOS flake driving my machines. Baseline shared by every host lives in `common/` (locale/timezone, nix settings, sshd + fail2ban, sysctl hardening, root-facing zsh/git/btop); the desktop is `desktop/` (user `nonplay`, home-manager, Niri), servers are `server/` (user `root`), the VPN stack is `proxy/`, home-manager lives in `home/`, package overlays in `overlays/`, sops store in `secrets/`. The authoritative host list is `nixosConfigurations` in `flake.nix` — read it there, never trust docs or memory for it.

## Hard rules

- Never build or apply configs (`nh os switch`, `nixos-rebuild`, `nix build` of a toplevel). I deploy myself. Never suggest `--target-host` / remote builds / pushing closures.
- Eval-only verification: `nix eval /etc/nixos#nixosConfigurations.<host>.config.system.build.toplevel.drvPath --raw`, or `nix flake check /etc/nixos` when touching shared files. `git add` new files first — flake eval ignores untracked files.
- Secrets never appear in `.nix` files — only sops placeholders/templates (`secrets/*.yaml`; `sops -d` works from my shell).
- Format `.nix` with `nixpkgs-fmt`.

## Mechanics

- `host`, `isServer`, `inputs` come via specialArgs; per-host gating via `lib.mkIf (host == "…")` or `isServer`.
- Flake module paths: `(base + "/path")`, never `"${base}/path"` — interpolation breaks relative imports inside modules.
- Anything in `common/` is evaluated by *both* the desktop and the servers. Options a machine overrides (`system.stateVersion`, `time.timeZone`) must be `lib.mkDefault` there; per-host additions to list options use `lib.mkAfter`.
- Yaml keys that would read as numbers (a user named `000`) must be quoted in the yaml; the parser in `secrets/default.nix` strips the quotes back off.
- `secrets/default.nix` derives `sops.secrets` by *parsing the yaml itself* — every `ENC[...]` leaf becomes a secret named by its `path/to/key`. Adding a secret means editing the yaml only; touch `secretOverrides` there just for a non-default owner/mode. Scope: `secrets.yaml` for all hosts, `home.yaml` desktop-only, `<host>.yaml` per server.
- New sops host: `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub` → add to `secrets/.sops.yaml` → `cd secrets && sops updatekeys <file>.yaml` for every file that host must decrypt.
- `overlays/default.nix` is a single `final: prev:` attrset; each package gets its own file next to it and is wired in with `prev.callPackage ./<name>.nix { }`.
- Desktop services live in `desktop/services/<name>/` but are imported by `desktop/machines/<host>/default.nix`, not by `desktop/configuration.nix` — put host-specific services there.
- sshd listens on **2022** everywhere (`common/sshd.nix`); fail2ban jails that port. Servers must also open it in `networking.firewall.allowedTCPPorts`.
- `home/shared/programs.nix` returns a *list* of module paths plus one inline module — add new home-manager programs to that list.
- mihomo (`desktop/services/mihomo`) is rendered from a sops template — tell me to restart it manually when its config changed.
- `proxy/` runs the VPN control plane ([xctrl](https://github.com/NONPLAYT/xctrl), a separate repo in `~/Projects/xctrl`). Day to day you only edit the three data files — `users.nix`, `groups.nix`, `nodes.nix`; `config.nix` renders them into the single JSON xctrl reads and everything else derives from there. `proxy/default.nix` decides per host which role it takes.
- nginx vhosts belong to the module that declares the service behind them; `server/services/nginx` is the baseline only, because both servers import it.
- stockholm's HTTP names are published through one cloudflared tunnel
  (`server/services/cloudflared`): `git`, `repo` and `mail` are CNAMEs to it and
  answer on loopback only. A service declares its own `ingress` line the way it
  declares its own vhost, off the `tunnel` module arg; `tunneled` is the vhost
  half of that and is taken only by a service that still needs nginx for
  something. nginx cannot be dropped: reality's cover needs a real certificate on
  `127.0.0.1:443`, `sub.bxteam.org` is deliberately not behind Cloudflare, and
  roundcube is php-fpm. kura and reposilite are plain HTTP upstreams, so for them
  the tunnel *is* the reverse proxy.
- A tunnelled name loses HTTP-01 with its A record, so it loses its certificate
  too and TLS ends at the edge. Anything that must keep one keeps a direct
  record: `stockholm.bxteam.org` and `sub.bxteam.org`.
- `stockholm.bxteam.org` is the only name still pointing at the box, so
  everything the tunnel cannot carry hangs off it: ssh pushes
  (`kura.settings.ssh.host`), the MX with imap and submission
  (`mailserver.fqdn`, which is also the HELO name -- the provider's PTR has to
  match it), reality's cover site and the xctrl agent API. Its ACME certificate
  is the one postfix and dovecot serve.
- The runner writes to `https://stockholm.bxteam.org/api/`, not through the
  tunnel: Cloudflare's free plan refuses a request body over 100 MB and a
  published release is bigger than that. Reads still come through the tunnel, and
  a download touches neither -- it points straight at the R2 bucket.
- Cloudflare's Redirect Rules -- the old Atlas paths on `api.bxteam.org` and
  `bxteam.org` -- run at the edge before any origin, and cloudflared's ingress
  cannot express a redirect. They stay in the dashboard, out of this repo, and
  the tunnel does not touch them.
- A node's `fqdn` in `nodes.nix` is how the controller reaches it, so it must resolve *and* be a vhost that node already serves — nodes have no name of their own, they hide behind a cover site (stockholm behind `repo.bxteam.org`, asgard behind a blank page). The agent API hangs off that vhost under `apiPath` from `proxy/default.nix`, never at the root; the same value is rendered as `api_path` for xctrl.
- A group is a tenant with its own xray inbound and reality keys; group to node is currently one to one (`personal`→stockholm, `asgard`→asgard); the subscription domain is `sub.bxteam.org`. Adding a user is a line in `users.nix`, its `proxy/users/<name>/{uuid,sub_token}` in sops, and a rebuild of the nodes serving that group — there is no runtime roster push by design.
- A user's `limit` overrides the group default, and `"unlimited"` opts out of it; `expires` is the last day the account works. Both are plain nix, only uuids/tokens/keys are sops.
- Client-side routing lives in `proxy/profiles/`: `clash.yaml` is the half of a mihomo profile that is not per-subscriber (xctrl prepends `proxies:`/`proxy-groups:`, so that file must declare neither, and its rules point at the `clash.selector` set in `config.nix`); `happ-routing.json` is served to Happ as a `happ://routing/onadd/…` line. Both are shared by every group.
- Quotas are enforced only by the controller (stockholm), because a limit belongs to a user, not a node. Admins are exempt from both blocking and auto-limiting.
- Changing `config.rs` in the xctrl repo is a breaking change for `proxy/config.nix`; the two are kept in sync by a contract test there.
