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
- Every node serves each group **twice**: vless+reality over XHTTP on TCP 8443 and hysteria2 on UDP 443, chosen per entry in `nodes.nix` by `protocol` (absent means vless). The tag is `<protocol>-<group>` and is derived identically in `xray.nix` and `config.nix` — they must agree or the agent provisions users into an inbound that does not exist. The vless half carries no `flow`: vision is RAW-only. Its `path` comes from `nodes.nix`; the inbound leaves `mode` unset so it accepts any client, and the subscription pins clients to `packet-up` — under REALITY an XHTTP client left on `auto` picks `stream-one`, which is one long-lived connection again and drops the way plain TCP did. Hysteria cannot hide behind reality: HTTP/3 needs a real certificate, so it takes the node's ACME one (hence `SupplementaryGroups` on the unit, which runs `DynamicUser`) and hides behind the same cover site by reverse-proxying unauthenticated callers into nginx on loopback. xray re-reads the certificate hourly, so an ACME renewal needs no restart.
- The hysteria inbound exists because UDP inside reality's single TCP connection stalls on every lost segment. `PROXY-UDP` in the clash profiles is generated from `clash.groups` in `config.nix` and holds only `hysteria2` endpoints, falling back to `PROXY` for a group that has none. A user's `uuid` doubles as the hysteria `auth` password, so no new sops secret.
- Only real-time traffic belongs in `PROXY-UDP`. The clash rules reach it through `AND,((NETWORK,udp),(…))`, so Discord's TCP stays on `PROXY`, and bulk QUIC is dropped (`AND,((NETWORK,udp),(DST-PORT,443),(DOMAIN-REGEX,.)),REJECT-DROP`) so browsers fall back to TCP instead of sharing one QUIC connection — and one congestion window — with voice and video. That rule sits below the DIRECT block, so it only ever touches proxied traffic, and the `DOMAIN-REGEX` is load-bearing: it fires only when a hostname is known, which is true of browser QUIC and never of real-time UDP dialled straight at an IP, so a Discord voice server on port 443 is not swallowed by it.
- Hysteria's UDP is QUIC datagrams, which are never retransmitted, and `proxy/hysteria/frag.go` reassembles one packet at a time — so a fragmented packet is lost to plain loss *and* to any reordering. A Discord video packet (~1200 B) plus the ~27-byte hysteria header does not fit xray's 1200-byte frame cap, while voice does, which is why streaming broke and calls did not. `overlays/xray.nix` raises that cap to 1500 and `datagramMtu` in `proxy/config.nix` hands clients a matching `udp-mtu`; mihomo splits by that number alone and never by what the server allows, so both halves have to move together. Raw xray clients (Happ) need no setting — they fragment only when the server refuses the size.
- xray hides hysteria's congestion controller under `streamSettings.finalmask.quicParams`, and unset means BBR, which answers loss by sending less — fatal for datagrams. Both ends run brutal instead, fed from `bandwidth` in `nodes.nix`: `node` becomes the inbound's `brutalUp`/`brutalDown`, `up`/`down` ride the subscription (`up:`/`down:` for mihomo, `up_mbps` for sing-box, another `finalmask` for a raw xray client). Brutal takes the lower of the two ends, and a client that advertises nothing keeps BBR, so the client numbers stay below what a subscriber plausibly has.
- A group is a tenant with its own xray inbound and reality keys; group to node is currently one to one (`personal`→stockholm, `asgard`→asgard); the subscription domain is `sub.bxteam.org`. Adding a user is a line in `users.nix`, its `proxy/users/<name>/{uuid,sub_token}` in sops, and a rebuild of the nodes serving that group — there is no runtime roster push by design.
- A user's `limit` overrides the group default, and `"unlimited"` opts out of it; `expires` is the last day the account works. Both are plain nix, only uuids/tokens/keys are sops.
- `PROCESS-NAME` rules need `services.mihomo.processesInfo` on the desktop; the option only exists to add `CAP_DAC_READ_SEARCH`/`CAP_SYS_PTRACE`, without which mihomo resolves no process and every such rule silently never matches. Never rely on one alone to keep traffic out of a `REJECT`.
- Client-side routing lives in `proxy/profiles/`: `clash.yaml` is the half of a mihomo profile that is not per-subscriber (xctrl prepends `proxies:`/`proxy-groups:`, so that file must declare neither, and its rules point at the `clash.selector` set in `config.nix`); `happ-routing.json` is served to Happ as a `happ://routing/onadd/…` line. Both are shared by every group.
- Quotas are enforced only by the controller (stockholm), because a limit belongs to a user, not a node. Admins are exempt from both blocking and auto-limiting.
- Changing `config.rs` in the xctrl repo is a breaking change for `proxy/config.nix`; the two are kept in sync by a contract test there.
