# Install Nix GitHub Action

A GitHub Action to install [Nix](https://nixos.org) using the [NixOS nix-installer](https://github.com/NixOS/nix-installer).

## Usage

**Basic usage:**

```yaml
- uses: NixOS/nix-installer-action@main
```

**With custom configuration:**

```yaml
- uses: NixOS/nix-installer-action@main
  with:
    extra-conf: |
      experimental-features = nix-command flakes
```

**Install specific version:**

```yaml
- uses: NixOS/nix-installer-action@main
  with:
    installer-version: v3.11.3
```

**No-init mode (for containers without systemd):**

```yaml
- uses: NixOS/nix-installer-action@main
  with:
    no-init: true
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `installer-version` | Installer version to use from releases | `latest` |
| `extra-conf` | Extra configuration lines to append to `/etc/nix/nix.conf` | |
| `logger` | Logger format: `compact`, `full`, `pretty`, `json` | `compact` |
| `verbosity` | Verbosity level: `0` (info), `1` (debug), `2` (trace) | `0` |
| `add-channel` | Setup the default system channels | `false` |
| `no-init` | Skip init system configuration (Nix will be root-only) | `false` |
| `trust-runner-user` | Add the current user to `trusted-users` in nix.conf | `true` |

## Supported Platforms

| Platform | Architecture |
|----------|--------------|
| Linux | `x86_64`, `aarch64`, `armv7l` |
| macOS | `x86_64`, `aarch64` |

## License

This project is licensed under the LGPL-2.1 License - see the [LICENSE](LICENSE) file for details.
