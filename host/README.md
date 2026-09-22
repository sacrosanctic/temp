# host/

The NixOS configuration for the deployment host. Flake root is here;
`sudo nixos-rebuild switch --flake ./host#azure`.

## Layout

- `modules/base.nix` — host config: hostname, users, sudo, timezone,
  nix settings, openssh/firewall enables, docker, system packages.
  Declares `user.name` and `user.sshPublicKeys` options consumed from `config.nix`.
- `config.nix` — host values only: `user.name`, `user.sshPublicKeys`.
- `modules/cron.nix` — per-minute check runner for the app in `~/app`.
- `modules/azure/` — platform modifier:
  - `default.nix` — Hyper-V guest, serial console, grub, hosts platform,
    and the upstream `azure-common` import.
  - `disk-config.nix` — disko layout; install-time truth only, inert on `switch`.

## First install (VM is not NixOS yet)

Commit + push first — nixos-anywhere builds from the git URL on the target.

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake ./host#azure \
  # needed if missing hardware section
  # --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  --target-host root@<ip/domain> \
  -i ./key.pem
```

Confirm deployment is successful
```sh
```


Delete temp keys
```sh
rm ./key.pem
```


## Steady-state updates (already NixOS)

```sh
sudo nixos-rebuild switch \
  --flake ./host#azure
  --target-host root@<ip/domain>
