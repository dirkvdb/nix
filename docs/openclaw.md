# OpenClaw on mediastation

`quadlets.openclaw.enable` runs the official `ghcr.io/openclaw/openclaw:latest`
image as `podman-openclaw.service`. `Pull=always` refreshes the image on every
service start. Like the other server Quadlets, this is a
system-level Podman service, not the upstream installer's rootless user service.
The container runs as the image's non-root `node` user (UID/GID 1000), with no
host container socket or host home directory mounted.

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
  without changing their ownership or permissions. They must be writable by
  container UID/GID 1000.
- Gateway token: generated once at runtime in `/var/lib/openclaw/env` (root-only).
- Declarative config: `modules/quadlets/openclaw/settings.nix`, mounted read-only.
  Change settings there and rebuild; container replacement picks up the new file.
  CLI/UI config writes are intentionally disabled (`OPENCLAW_CONFIG_READONLY=1`).

Back up both `/nas/docker/openclaw/config` and `/nas/docker/openclaw/data`, plus
`/var/lib/openclaw/env`, before image upgrades. OpenClaw's image entrypoint runs
Doctor to migrate retained state. Backups may be needed to roll back an image
and its matching database schema together.

If an earlier deployment kept all state in `/var/lib/openclaw/state` or directly
in `/nas/docker/openclaw/data`, stop the service and back up that directory first.
Copy the old state into `/nas/docker/openclaw/config` and place the contents of
its old `workspace` subdirectory directly in `/nas/docker/openclaw/data`,
preserving UID/GID 1000. Existing data is not moved automatically or deleted.

`/nas/docker` is an NFS mount. Its export permissions must allow container
UID/GID 1000 access. OpenClaw's SQLite databases and
state ownership checks require reliable filesystem locking; a successful Nix
build does not verify NAS compatibility. If startup reports unsupported locking
or state-ownership primitives, stop the service and use a compatible filesystem
rather than bypassing those checks.

## Dashboard access

Only host loopback ports **18789** (gateway) and **18790** (bridge) are published;
no firewall ports are opened. From your workstation, keep an SSH tunnel open:

```sh
ssh -N -L 18789:127.0.0.1:18789 dirk@mediastation
```

Open <http://127.0.0.1:18789> and paste the gateway token into the dashboard's
authentication settings. Read it on mediastation (do not share the output):

```sh
sudo cat /var/lib/openclaw/env
```

If the dashboard requests device pairing, list and approve the matching request
on mediastation:

```sh
sudo podman exec openclaw openclaw devices list
sudo podman exec openclaw openclaw devices approve REQUEST_ID
```

Replace `REQUEST_ID` with the ID from the list. Do not disable device authentication
or expose the gateway on the LAN just to bypass pairing.

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
[custom providers](https://docs.openclaw.ai/concepts/model-providers/custom-providers).
