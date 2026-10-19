# Frigate

Frigate runs the pinned `ghcr.io/blakeblackshear/frigate:0.17.2` image as
`frigate.service`. The authenticated HTTP UI is at port `8085`; the
unauthenticated API and go2rtc ports are not exposed. TLS is disabled.
The container's bundled go2rtc replaces the standalone service.

## Configuration

Camera and recording settings live in [`settings.nix`](settings.nix).
SOPS supplies the MQTT and camera credentials, notification email, and admin
password. Runtime configuration is regenerated from Nix on every restart, so
UI configuration edits are not persistent.

## GPU acceleration

The Quadlet passes `/dev/dri/renderD128` through with read/write access and uses
`preset-vaapi` for Intel GPU video decoding (including Skylake HD Graphics 530).
The host must expose this render node; the container supplies its own userspace
drivers. No privileged mode or host graphics-library mounts are needed. Explicit
VAAPI configuration does not fall back to CPU decoding if GPU initialization fails;
check `sudo journalctl -u frigate.service` for FFmpeg/VAAPI errors after deployment.

Object detection uses an OpenVINO GPU detector with the bundled FP16 SSDLite
MobileNet v2 model (300×300 input). It is enabled for `benchcam` at 5 detection fps
using its substream; `birdcam` object detection remains disabled. Motion analysis
still runs on the CPU. GPU discovery can be checked with:

```sh
sudo podman exec frigate python3 -c 'from openvino import Core; print(Core().available_devices)'
```

The detector explicitly selects `GPU` rather than falling back to CPU inference.
After deployment, check the service logs for OpenVINO model compilation errors
and Frigate's System Metrics for detector `ov` inference times and skipped frames.
GPU discovery alone does not verify successful model execution.

## Migration from the native service

The existing `/var/lib/frigate` directory is mounted in place for both the
database and media. Before container startup, known native media paths in the
database are normalized to `/media/frigate/` so existing previews, recordings,
and exports remain accessible. This is transactional and creates a mode-`0600`
SQLite backup at `/var/lib/frigate/frigate.db.pre-quadlet-<unique>.backup` before
changing any paths; its location is logged to the service journal. The original
absolute path remains mounted as well for legacy paths.

Before first activation, stop the native Frigate service and back up
`/var/lib/frigate` (including the database and its SQLite journal files). Never
run native Frigate and the Quadlet against the database simultaneously. Normal
Frigate schema migrations may occur; container-created files may be root-owned.
For a native-service rollback, stop the Quadlet and restore the pre-migration
database backup and suitable native ownership rather than sharing a live
container database.
