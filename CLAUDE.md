# CLAUDE.md

This file provides guidance to AI coding agents when working with code in this repository.

## Repository Overview

NixOS flake by **nonplay** managing 2 x86_64 hosts:
- **Desktop**: `ms-7c56` (AMD CPU + NVIDIA GPU, Hyprland, dual-boot with Windows 11)
- **VPS**: `stockholm` (proxy/tunnel node, Docker services)

Stack: home-manager for the user environment, sops-nix with **SSH-host-key-derived age recipients**, catppuccin theming, Limine + Secure Boot on the desktop.

## Build Commands

```bash
# Server (stockholm) — nh is configured there with flake = /etc/nixos
nh os switch

# Any host via stock nixos-rebuild
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# Eval / build a host without applying
nix build /etc/nixos#nixosConfigurations.<hostname>.config.system.build.toplevel -L

# Hostnames: ms-7c56, stockholm
```

## Agent rules

- **Do NOT run `nixos-rebuild switch` / `boot` / `nh os switch` / a toplevel `nix build`** — the user applies configs manually, and a full build is wasted work when only the eval state matters.
- **When unsure a change evaluates**, do an eval-only check (writes only the `.drv`, no builders run):
  - One host: `nix eval /etc/nixos#nixosConfigurations.<host>.config.system.build.toplevel.drvPath --raw`
  - All outputs at once (when touching shared files like `flake.nix`, `server/secrets/`, `*/configuration.nix`): `nix flake check /etc/nixos`
  - Catches module type errors, missing options, assertion failures, bad paths. Does NOT catch builder-time failures inside upstream packages.
- **There is no `nix` in the dev environment where edits are made** (Windows workstation). Builds/evals run on the target hosts, not here.
- **Prefer this CLAUDE.md over auto-memory `feedback` notes.** Durable repo-wide rules belong here so they land in git.

## Architecture

```
flake.nix                    # Inputs + nixosConfigurations (single mkSystem builder for both hosts)
├── system/                  # Desktop config (base = ./system, isServer = false)
│   ├── configuration.nix    # Shared base: NetworkManager, locale (en_US + ru_RU LC_*), bluetooth,
│   │                        #   Hyprland (UWSM), openssh, avahi, user `nonplay`, home-manager wiring
│   ├── machines/
│   │   └── ms-7c56/         # AMD CPU + NVIDIA (beta driver), Limine + Secure Boot, Win11 dual-boot entry
│   ├── services/            # System service modules — default.nix is a LIST, imported via lib.concatMap import
│   │   ├── dbus/ greetd/ pipewire/ systemd/ mihomo/
│   └── home/                # home-manager config for `nonplay`
│       ├── home.nix         # Entry: packages, fonts, xdg (portals, userDirs), sessionVars, catppuccin
│       ├── hyprland.nix     # Hyprland HM toggle (hyprland.enable = true)
│       ├── plasma.nix       # Plasma HM toggle (plasma.enable = false — Hyprland is active)
│       ├── programs/        # Per-program HM modules (default.nix = LIST + inline `more` w/ jetbrains idea)
│       │                    #   albert, dconf, fastfetch, firefox, git, kitty, noctalia, zed, zsh
│       ├── services/        # HM services (default.nix = LIST: hypridle + inline gnome-keyring)
│       └── themes/          # GTK/Qt/catppuccin theming (default.nix = LIST)
├── server/                  # VPS config (base = ./server, isServer = true)
│   ├── configuration.nix    # Shared server base: domain, sysctl hardening, root user, nh, sops import
│   ├── machines/
│   │   └── stockholm/       # QEMU guest, GRUB, static IPv4 207.2.123.110/24, Europe/Stockholm
│   ├── programs/            # Server programs (btop, git, ssh, zsh)
│   ├── secrets/             # SINGLE SOPS store for the server tree
│   │   ├── default.nix      # sops module: owns defaultSopsFile, all secrets + templates
│   │   ├── secrets.yaml     # Encrypted (created with `sops`); recipients = admin + stockholm host key
│   │   └── .sops.yaml       # Recipients list / creation_rules
│   └── services/            # All Docker-based (oci-containers, backend = docker)
│       ├── docker/          # virtualisation.docker + oci-containers backend + weekly autoPrune
│       ├── sshd/            # sshd port 2022 + fail2ban (nftables backend)
│       ├── frp/             # frps tunnel server (snowdreamtech/frps) — frps.toml via sops template
│       ├── mtprotoproxy/    # Telegram MTProto proxy (alexbers/mtprotoproxy) — config.py via sops template
│       └── pg-node/         # PasarGuard node (pasarguard/node) — .env + TLS certs via sops
```

## Key Patterns

- **Single flake builder**: `mkSystem { host, system, base }` in `flake.nix` builds both hosts. `base` is `./system` (desktop) or `./server` (VPS); it imports `${base}/configuration.nix` + `${base}/machines/${host}`.
- **`isServer` flag**: derived in `specialArgs` as `base == ./server`. Available to every module for `lib.mkIf isServer` gating. `host` is also passed through `specialArgs`.
- **List-style aggregators**: `system/services/default.nix`, `home/programs/default.nix`, `home/services/default.nix`, `home/themes/default.nix` each return a **list of module paths** (sometimes plus an inline `more` module), consumed via `lib.concatMap import`. Add a module by dropping its path into the list.
- **Server services are all Docker**: every module under `server/services/` (except `sshd`) declares a `virtualisation.oci-containers.containers.<name>`. Config/secret files are mounted read-only from sops template paths. None build from a Nix package.
- **WM toggles**: `home/home.nix` imports both `hyprland.nix` and `plasma.nix` as HM options; exactly one is enabled (`hyprland.enable = true`, `plasma.enable = false`). Portals/xdg config branches on these via `lib.mkIf`.
- **catppuccin theming**: applied at both NixOS (`catppuccin.nixosModules.catppuccin`) and HM level; flavor `macchiato`, accent `lavender` (set in `home/home.nix`).

## Secrets (sops-nix)

- **Single server store** at `server/secrets/`. `default.nix` is the only module that owns sops config: it sets `defaultSopsFile = ./secrets.yaml`, declares every `sops.secrets.*` and every `sops.templates.*`. Service modules ONLY reference the rendered paths (`config.sops.templates."...".path`) — they never declare secrets themselves.
- **Decryption on the server**: via `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]` — the host's SSH key is converted to an age key automatically.
- **Recipients** (`server/secrets/.sops.yaml`): `admin` (personal age key, for CLI editing) + `stockholm` (server SSH-host-derived age key). `creation_rules` regex matches `secrets.yaml$`.
- **Editing**: `sops server/secrets/secrets.yaml`. **Adding a host**: get its `/etc/ssh/ssh_host_ed25519_key.pub`, `ssh-to-age` it, add to `.sops.yaml`, then `cd server/secrets && sops updatekeys secrets.yaml`.
- **Secrets schema** (what goes in `secrets.yaml`):
  - `mtproto.secret` — 32 hex chars (MTProto user secret)
  - `frp.token` — shared frps/frpc auth token; `frp.dashboard-password` — web dashboard password
  - `pg-node.api-key` — a valid UUID; `pg-node.ssl_cert` / `pg-node.ssl_key` — PEM, written to `/var/lib/pg-node/certs/`
- **Template targets**: `mtprotoproxy-config.py` → `/home/tgproxy/config.py`; `frps.toml` → `/etc/frp/frps.toml`; `pg-node.env` → container `environmentFiles`. Service ports/users live in the `let` block at the top of `server/secrets/default.nix`.

## Key Details

- **Flake inputs**: nixpkgs (unstable), nixpkgs-firefox (pinned to a commit for firefox-beta 148.0b3, avoids source build), home-manager, nix-index-database, sops-nix, catppuccin, noctalia, nixos-hardware.
- **NixOS version**: desktop `ms-7c56` → stateVersion `26.05`; server `stockholm` → stateVersion `24.11`. Channel: `nixos-unstable`.
- **User**: `nonplay` (normal user, wheel/networkmanager/audio/video/input/dialout) on `ms-7c56`; `root` on `stockholm` (getty autologin, zsh).
- **Locale**: `en_US.UTF-8` default with `ru_RU.UTF-8` for LC_TIME/NUMERIC/MONETARY/MEASUREMENT/PAPER on both hosts. Timezone: Europe/Moscow (desktop), Europe/Stockholm (server).
- **Desktop stack**: Hyprland via UWSM + greetd + Noctalia shell + Kitty + PipeWire + NetworkManager. NVIDIA beta driver, AMD CPU (nixos-hardware common-cpu-amd). RTL8821CU wifi out-of-tree module on kernel 6.18.
- **Bootloader**: `ms-7c56` uses **Limine** with Secure Boot (sbctl) + a Windows 11 chain entry + catppuccin-mocha terminal palette; `stockholm` uses GRUB on `/dev/sda`.
- **firefox-beta**: installed from the pinned `nixpkgs-firefox` input; default BROWSER in HM sessionVariables.
- **JetBrains IDEA**: in `home/programs/default.nix` via an override — custom vmopts (WLToolkit, ja-netfilter agent) and a CloudFront mirror for the source URL. `allowUnfreePredicate` whitelists only `jetbrains.idea`.
- **Proxy**: `mihomo` system service on the desktop (`system/services/mihomo`). The server runs **frps** (frp tunnel), **mtprotoproxy** (Telegram), and **pg-node** (PasarGuard) — all Docker.
- **Network hardening**: `boot.kernel.sysctl` block in both bases (accept_redirects=0 v4+v6, send_redirects=0, rp_filter=2 loose, log_martians=1, tcp_max_syn_backlog=4096, somaxconn=4096, netdev_max_backlog=5000).
- **Server firewall**: `networking.firewall.enable = false` on `stockholm` (lib.mkDefault) — service ports are open to the internet. `nftables` is enabled and `fail2ban` guards sshd (port 2022). **Note**: the frps dashboard (7500) is internet-exposed; only the sops password protects it.
- **Desktop firewall**: NixOS firewall enabled, no extra ports opened by default. Spotify ad domains pinned to a sinkhole IP via `networking.extraHosts`.
- **SSH**: desktop sshd on default port; server sshd on **2022**, password auth off, root key-only.
- **Formatter**: `.nix` files follow the existing nixpkgs-style 2-space layout. Match surrounding style; don't reflow files wholesale.
- **`nh`**: configured on the server with `flake = "/etc/nixos"`.

## Host-Specific Features

| Host | Role | Key Features |
|------|------|--------------|
| `ms-7c56` | Desktop | AMD CPU + NVIDIA (beta driver), Hyprland/UWSM + Noctalia, Limine + Secure Boot, Windows 11 dual-boot, RTL8821CU wifi, JetBrains IDEA, mihomo client, firefox-beta, gaming (prismlauncher/packwiz), Spotify |
| `stockholm` | VPS | QEMU guest, GRUB, static IPv4 (207.2.123.110/24), Docker: frps + mtprotoproxy + pg-node, sops-nix (SSH-host-key age), sshd:2022 + fail2ban/nftables, `nh` |
