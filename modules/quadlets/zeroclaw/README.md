# ZeroClaw Quadlet

Enable with `quadlets.zeroclaw.enable = true;` (enabled on `mediastation`).
The container uses the official `ghcr.io/zeroclaw-labs/zeroclaw:v0.8.6` image.
The image is distroless and does not include a shell.

## Persistent storage

| Host directory | Container directory | Contents |
| --- | --- | --- |
| `/nas/docker/zeroclaw/config` | `/zeroclaw-data/.zeroclaw` | Configuration, credentials, pairing state, and shared runtime databases in `data/` |
| `/nas/docker/zeroclaw/data` | `/zeroclaw-data` | Container home |
| `/nas/docker/zeroclaw/data/agents` | `/zeroclaw-data/.zeroclaw/agents` | Agent workspaces and memory |

The nested agent mount keeps agent data out of the config directory.
The service waits for the NAS mount and creates missing directories using
`mkdir -p`, without changing ownership or permissions on existing directories.
The container runs as `1024:100`, matching the existing NAS directory owner,
instead of the image's default `65534:65534`. ZeroClaw requires its lifecycle
directory (`config/data` on the host) to be owned by its effective UID;
write access alone is insufficient. Ownership and access remain NAS-managed.
Existing world-writable directories are not hardened by the service, so NAS
access restrictions matter because configuration includes credentials.
Back up both directories and keep their contents private.

Existing state in `/var/lib/zeroclaw` is not moved or deleted automatically.
If migrating an existing installation, stop the service and back up its state
before copying `.zeroclaw/` into `config/`, the remaining data into `data/`,
and `.zeroclaw/agents/` into `data/agents/`. Preserve file permissions and ensure
the copied files are accessible to `1024:100` and the lifecycle directory is
owned by UID `1024` before starting the new service.

## Manual onboarding

After deploying the configuration, run on `mediastation`:

```sh
sudo podman exec -it zeroclaw zeroclaw quickstart
```

To use the same OpenAI-compatible provider as OpenClaw, configure:

- Provider: custom OpenAI-compatible, using Chat Completions.
- Endpoint: `https://ai.hl.vandenboer.eu/v1`.
- Model: `qwen3.6-moe-35b-a3b-FLM`.
- API key: none (the Lemonade endpoint is unauthenticated).
- Request timeout: `600` seconds.
- Context window: `65536`; maximum output tokens: `8192`.
- Embeddings: disabled (no embedding model is configured).

Assign the provider to your agent during setup. Settings are persisted in
`/nas/docker/zeroclaw/config/config.toml` and are not rewritten by Nix on
restart. Gateway bind, pairing, and remote-administration settings remain
enforced by the Quadlet's environment variables.

Restart after onboarding if needed:

```sh
sudo systemctl restart podman-zeroclaw.service
```

## Dashboard

Open <https://zeroclaw.hl.vandenboer.eu/> (also linked from Homepage).
Configure the external reverse proxy to forward to `http://mediastation:42617`,
with TLS termination and WebSocket upgrade support. No SSH tunnel is required.

Port `42617` is published on IPv4, with ingress restricted to the same proxy
addresses as OpenClaw (`192.168.1.13` and `192.168.1.14`) plus host-local access.
The ingress filter is installed before the container starts and runs before
Podman's DNAT so container port publishing cannot bypass the restriction.
Pairing remains enabled, overriding the image's unauthenticated default.
Authenticated remote administration is enabled for dashboard configuration
through the proxy; forwarded client-IP headers are not trusted.

Generate a fresh pairing code on the host when needed:

```sh
sudo podman exec -it zeroclaw zeroclaw gateway get-paircode --new
```

Homepage monitors the local upstream at `http://127.0.0.1:42617/` independently
of the external proxy. The proxy and DNS record are managed separately.

## Operations

```sh
systemctl status podman-zeroclaw.service
journalctl -u podman-zeroclaw.service -f
sudo podman exec zeroclaw zeroclaw status --format=exit-code
```

Upgrade by changing the pinned image tag in `default.nix` and rebuilding.

Reference: <https://docs.zeroclaw.com/v0.8.6/en/setup/container.html>
