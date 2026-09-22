# nix/

The NixOS configuration for the deployment host.

```sh
sudo nixos-rebuild switch --flake .#azure
```

## Layout

- `nix/config.nix` — host values only: `user.name`, `user.sshPublicKeys`.
- `nix/modules/base.nix` — host config: hostname, users, sudo, timezone, nix settings, openssh/firewall enables, docker, system packages. Declares `user.name` and `user.sshPublicKeys` options consumed from `nix/config.nix`.
- `nix/modules/cron.nix` — per-minute check runner for the app in `~/app`.
- `nix/modules/azure/` — platform modifier:
  - `default.nix` — Hyper-V guest, serial console, grub, hosts platform, and the upstream `azure-common` import.
  - `disk-config.nix` — disko layout; install-time truth only, inert on `switch`.

## First install (VM is not NixOS yet)

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake .#azure \
  # needed if missing hardware section
  # --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --target-host root@<ip/domain> \
  -i ./key.pem
```

Confirm deployment is successful

```sh
ssh root@<ip/domain> '
  hostname                      # expect: nixos
  systemctl is-system-running   # expect: running (degraded => check systemctl --failed)
  nixos-rebuild list-generations | head -n 5
'
```

Delete temp keys

```sh
rm ./key.pem
```

setup app

`nix/modules/cron.nix` + `nix/modules/run.sh` run `~/app/scripts/ci.sh`
every minute as `user.name` from `nix/config.nix` (e.g. `/home/sw/app`).
Without this checkout cron only logs `warn: ... missing, skipping`
to `~/cron/output.log` and nothing deploys.

```sh
ssh <user>@<ip/domain> '
  git clone <repo-url> ~/app
  # future private repo over SSH:
  # git clone git@github.com:<org>/<repo>.git ~/app
  test -x ~/app/scripts/ci.sh
  git -C ~/app status -sb
'
```

Notes:

- Clone as `<user>`, not `root`, at exactly `~/app` (`/home/<user>/app`).
- A plain clone is enough — `scripts/ci.sh` relies on `@{u}` upstream
  tracking via `git fetch`; avoid `--depth` / detached checkouts that
  break it.
- Verify with `tail ~/cron/output.log` and `systemctl status cron`.

## Steady-state updates (already NixOS)

```sh
sudo nixos-rebuild switch \
  --flake .#azure
  --target-host root@<ip/domain>
```
