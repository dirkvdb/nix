# OpenClaw on mediastation

`quadlets.openclaw.enable` runs the official `ghcr.io/openclaw/openclaw:latest`
image as `podman-openclaw.service`. `Pull=always` refreshes the image on every
service start. Like the other server Quadlets, this is a
system-level Podman service, not the upstream installer's rootless user service.
The container runs as non-root UID/GID `1024:100`, matching the existing NAS
storage owner, with no host container socket or host home directory mounted.

## Models and state

Agents and subagents default to **Qwen 3.6 MoE 35B A3B**, served by Lemonade at
`https://ai.hl.vandenboer.eu/v1` using OpenAI-compatible Chat Completions.
The model ID is `qwen3.6-moe-35b-a3b-FLM`, with the server's advertised 65,536-token
context window and an 8,192-token output cap. No cloud fallback is configured.
The provider key is a non-secret dummy value: the endpoint currently needs no
authentication. Embedding-backed memory search is disabled because no embedding
model is configured; workspace files and session state remain persistent.

- Configuration and agent state (credentials, sessions and databases):
  `/nas/docker/openclaw/config`, mounted at `/home/node/.openclaw` in the container.
- Workspace and agent files: `/nas/docker/openclaw/data`, mounted at
  `/home/node/.openclaw/workspace` in the container.
- The service waits for the NAS mount and bind-mounts the existing directories
  without changing their ownership or permissions. The configuration directory
  must be owned by UID 1024, not just writable: OpenClaw checks that its state
  belongs to the running user. Both directories must be writable by UID/GID `1024:100`.
  OpenClaw itself enforces mode 0700 on its ownership directories; the NAS ACLs
  must allow that permission change.
- Temporary files and cache: a private in-memory `/tmp/openclaw` owned by
  UID/GID `1024:100` with mode 0700. Both `TMPDIR` and `XDG_CACHE_HOME` point
  there. SQLite snapshot staging uses `XDG_CACHE_HOME` independently of `TMPDIR`;
  without it, startup fails trying to create `/home/node/.cache/openclaw-1024`
  in the image's UID-1000 home directory. These temporary files do not survive
  container replacement; persistent databases remain on the NAS.
- Gateway token: generated once at runtime in `/var/lib/openclaw/env` (root-only).
- Initial configuration: `modules/quadlets/openclaw/settings.nix`, supplied as
  `/etc/openclaw/defaults.json`. Startup seeds a writable
  `/home/node/.openclaw/openclaw.json` only if it is missing or empty. Existing
  configuration is preserved so plugin installation and guided UI setup can
  save changes. Changing the Nix defaults does not overwrite an existing config;
  edit that config through OpenClaw or on the NAS instead.

Back up both `/nas/docker/openclaw/config` and `/nas/docker/openclaw/data`, plus
`/var/lib/openclaw/env`, before image upgrades. OpenClaw's image entrypoint runs
Doctor to migrate retained state. Backups may be needed to roll back an image
and its matching database schema together.

If an earlier deployment kept all state in `/var/lib/openclaw/state` or directly
in `/nas/docker/openclaw/data`, stop the service and back up that directory first.
Copy the old state into `/nas/docker/openclaw/config` and place the contents of
its old `workspace` subdirectory directly in `/nas/docker/openclaw/data`,
with ownership matching UID/GID `1024:100`. Existing data is not moved automatically or deleted.

`/nas/docker` is an NFS mount. Its export permissions must allow container
UID/GID `1024:100` access. OpenClaw's SQLite databases and
state ownership checks require reliable filesystem locking; a successful Nix
build does not verify NAS compatibility. If startup reports unsupported locking
or state-ownership primitives, stop the service and use a compatible filesystem
rather than bypassing those checks.

### Confirmed NFS atomic-write incompatibility

With OpenClaw 2026.10.5 / `@openclaw/fs-safe` 0.25.0, chat initialization on
this Synology NFS export fails with `FsSafeError: staged file publish failed`.
An isolated test on the same export exposed the underlying
`hardlinked path not allowed` error after successful publication.

The no-clobber publication fallback links the staged file to its destination,
then unlinks the still-open staging name. Linux NFS preserves that open name as
`.nfs…` until its descriptor closes, leaving two hard links during OpenClaw's
verification. The probe confirmed two names/link count 2 while open, followed by
one name/link count 1 after closing. The same operation passes on local storage.

Changing ownership, disabling attribute caching, or disabling the native
fs-safe backend does not solve this open-unlink behavior. Do not bypass the
hardlink safety check, delete live `.nfs…` files, or assume the database is
corrupt. The existing NAS binds are preserved; resolving this requires an
upstream-compatible publication implementation or migrating the affected live
storage to a compatible local filesystem after stopping the service and
backing up state.

## Signal and npm plugins

On container creation, `start.mjs` installs Signal through OpenClaw's npm
installer before handing control back to the image's Doctor/gateway entrypoint:

```sh
openclaw plugins install npm:@openclaw/signal --force --accept-capabilities
```

This uses the installer’s host-version compatibility selection, records plugin
provenance, and enables Signal. The plugin is not packaged or version-pinned in
Nix. `--force` permits updating an existing installation; only this explicitly
requested plugin is installed automatically. Other npm plugins and channel
settings can be managed through OpenClaw. Config, plugin files and install
records persist under `/nas/docker/openclaw/config`. The npm cache is persistent
too. Creation needs access to the npm registry and fails if installation fails;
it does not silently start without the requested plugin. Installation is
bounded to ten minutes.

`signal-cli` and its Java runtime are provided read-only by Nix. Only their
runtime closure is mounted, not the host's entire Nix store. The OpenClaw image
remains `ghcr.io/openclaw/openclaw:latest` with `Pull=always`.

Complete Signal's guided setup in the UI, or run:

```sh
sudo podman exec -it openclaw openclaw channels add --channel signal
```

Prefer a dedicated bot Signal number. To link an existing Signal account:

```sh
sudo podman exec -it openclaw signal-cli --config /home/node/.openclaw/signal-cli link -n OpenClaw
```

Complete authorization in Signal's linked-device settings. Do not register your
personal number blindly: registration can de-authenticate its existing Signal
app. Messages sent by the linked account itself are ignored by loop protection.
After setup, check the channel and approve the first sender's pairing code:

```sh
sudo podman exec openclaw signal-cli --version
sudo podman exec openclaw openclaw channels status --probe
sudo podman exec openclaw openclaw pairing list signal
sudo podman exec openclaw openclaw pairing approve signal PAIRING_CODE
```

Signal account keys persist in `/nas/docker/openclaw/config/signal-cli`, mounted
at `/home/node/.openclaw/signal-cli`. `XDG_DATA_HOME` points at the persistent
state directory so direct CLI commands use the same storage by default.
Back up these keys as sensitive credentials. Keep the Signal daemon bound to
container loopback, retain DM pairing, and restrict groups during setup. No
extra host port is published. Signal replies still depend on resolving the NFS
atomic-write issue above.

## GitHub authorization

The container also includes the GitHub CLI (`gh`), required by OpenClaw's GitHub
authorization flow. `GH_CONFIG_DIR=/home/node/.openclaw/gh` keeps authorization
state on the NAS rather than the image's unwritable home directory. Complete
GitHub authorization in the UI after deployment; no token is stored in Nix.

```sh
sudo podman exec openclaw gh --version
```

## Dashboard access

Open <https://claw.hl.vandenboer.eu> through your external reverse proxy; no SSH
tunnel is required. Homepage links to this address.

Configure the reverse proxy with:

- HTTPS frontend: `claw.hl.vandenboer.eu`, with a valid TLS certificate.
- HTTP upstream: `http://mediastation:18789` (or mediastation's LAN IP on port 18789).
- WebSocket support enabled, including HTTP/1.1 `Upgrade` / `Connection` handling
  and timeouts suitable for long-lived connections.
- Preserve the public `Host` and browser `Origin`; set `X-Forwarded-Proto: https`
  and overwrite `X-Forwarded-For` with the actual client IP rather than trusting
  client-supplied forwarding headers.

Both reverse-proxy addresses, `192.168.1.13` and `192.168.1.14`, are trusted by
OpenClaw. Gateway port **18789** is published on IPv4 host interfaces, with a
service-managed packet filter allowing remote access only from these two IPs.
The filter runs before Podman's port-forwarding rules and does not depend on
the host's currently disabled firewall service. Local health checks still work.
Bridge port **18790** remains loopback-only and must not be proxied.

Token authentication and device pairing remain enabled. Paste the gateway token
into the dashboard's authentication settings. Read it on mediastation (do not
share the output):

```sh
sudo cat /var/lib/openclaw/env
```

If the dashboard requests device pairing, list and approve the matching request
on mediastation:

```sh
sudo podman exec openclaw openclaw devices list
sudo podman exec openclaw openclaw devices approve REQUEST_ID
```

Replace `REQUEST_ID` with the ID from the list. The HTTPS origin has its own
browser identity, so a browser previously paired through localhost may need a
new approval. Do not disable device authentication to bypass pairing.

If logs report `proxy_attribution_required`, verify that the immediate proxy
peer seen by the gateway is one of the two configured IPs. Do not work around
this by trusting an entire LAN or container subnet.

## Operations

Run on mediastation after deploying the configuration:

```sh
sudo systemctl status podman-openclaw.service
sudo journalctl -u podman-openclaw.service -f
sudo podman exec openclaw openclaw config validate
sudo podman exec openclaw openclaw models status
curl --fail http://127.0.0.1:18789/healthz
```

The host does not need the OpenClaw CLI. Provider reachability, inference and
channel setup should be checked after deployment; a Nix build does not pull or
start this OCI image.

References: [Podman installation](https://docs.openclaw.ai/install/podman),
[Docker image](https://docs.openclaw.ai/install/docker), and
[custom providers](https://docs.openclaw.ai/concepts/model-providers/custom-providers), and
[Signal](https://docs.openclaw.ai/channels/signal).
