# Dell U2725QE backlight returns during display sleep

Investigation recorded: **2026-10-13**. Host: **`mini`** (`hosts/minisforum-ai-x1`).

## Status and conclusion

**The immediate wake mechanism was identified by kernel tracing:** AMD's hotplug-detection worker performs destructive DisplayPort link-capability verification while the display is asleep. That verification temporarily powers the receiver back up (D0), trains the link, and powers it down again (D3). The user observed the Dell's backlight returning during this activity, before the normal desktop wake.

A targeted workaround was added to this host's kernel parameters:

```nix
"amdgpu.dcdebugmask=0x200000"
```

This bit is **`DC_SKIP_DETECTION_LT`**. It skips detection-time link training, while retaining normal modeset/wake training.

**Important status boundary:** `just build` passed and the evaluated configuration includes the parameter. At the end of this investigation, the agent had **not activated the configuration or rebooted**, and the user had **not yet reported a successful post-workaround standby test**. Do not treat this document as confirmation that the workaround has fixed every occurrence.

The underlying reason for the delayed hotplug-detection event, and the exact kernel change that introduced the regression, remain unidentified. The trace establishes the immediate mechanism, not a bisected upstream regression commit.

## System and constraints

- AMD Strix Point system, Display Core DCN 3.5.
- Affected monitor: **Dell U2725QE**, connected through **DisplayPort**, Hyprland output **DP-3**.
- Normal mode: **3840×2160 at 120 Hz**, 10-bit `XRGB2101010`, SDR, VRR off, scale approximately 1.67.
- Other outputs:
  - DP-1: Dell P2214H, 1920×1080 at 60 Hz, 8-bit.
  - SUNSHINE: persistent headless output used by Sunshine.
- Hyprland **0.55.4**, commit `a0136d8c04687bb36eb8a28eb9d1ff92aea99704`, using Lua configuration.
- Aquamarine **0.11.0**.
- Noctalia **5.2.1** owns idle screen-off; no separate `hypridle` was running.
- `hyprmoncfgd.service` manages monitor profiles.
- Original Noctalia idle timeout was 600 seconds. For the final trace, the user had temporarily changed it to **30 seconds**.

The latest standard kernel is required for the user's Lemonade/FastFlowLM NPU workload. Returning permanently to the stable kernel was not an acceptable solution.

### Kernel comparison

| Kernel | Hard hangs | Dell standby / NPU observations |
|---|---|---|
| Standard stable `6.18.55` | Not observed | Display sleeps correctly; `amdxdna` 0.1.0 does not support the user's required NPU requests/workload |
| Standard latest `7.2.9` | Not observed | Backlight problem reproduced; `amdxdna` 0.10.0 supports the required workload |
| Standard latest `7.2.10` | Backlight investigation continued here | Final call-stack trace reproduced the problem on this version |
| CachyOS `7.2.8-cachyos-lto` | Reproducible | Separate stability problem; keep CachyOS disabled |

The configuration retains:

```nix
local.system.kernel = {
  cachyos.enable = false;
  useLatest = true;
};
```

Both previously compared standard kernels loaded DMUB firmware `0x09005300`. Display Core versions were `3.2.351` on the stable kernel and `3.2.384` on latest `7.2.9`. This is GPU firmware information, **not the Dell monitor's firmware version**.

The old CachyOS hangs included a recorded hardware-watchdog reset. They should not be conflated with this DisplayPort sleep issue.

## Experiments and evidence

### 1. Refresh rate was not the solution

The user tested 60 Hz. Runtime queries confirmed the Dell really was at 4K60, but the backlight problem persisted. It seemed somewhat better, not fixed.

Initially, `hyprmoncfgd` was also trying to reconcile a profile expecting 120 Hz:

```text
DP-3 refresh mismatch: wanted 120.00, got 60.00
compositor query timed out (monitors): context deadline exceeded
```

That was a genuine test confounder, not proof of the backlight cause. Later testing was back at 120 Hz with the profile applying successfully. The daemon detected sleep and paused automatic switching.

### 2. Kernel display state really reached off

A passive capture on 2026-10-13 recorded the normal idle transition without forcing DPMS or changing display modes.

Local capture: `result-dpms-capture/dpms-dNitoc4N/`.

- 08:56:11: Noctalia requested screen-off.
- 08:56:12: `hyprmoncfgd` detected sleep and paused.
- 09:11:58: Noctalia recorded the user's wake.

At all five off-state checkpoints (approximately 0, 2, 10, 30 and 120 seconds):

| State | Dell DP-3 | Other physical display DP-1 |
|---|---|---|
| Hyprland `dpmsStatus` | `false` | `false` |
| DRM connector `DPMS` | `3` (Off) | `3` (Off) |
| DRM connector `CRTC_ID` | `0` (detached) | `0` (detached) |
| DRM CRTC `ACTIVE` | All CRTCs were `0` | All CRTCs were `0` |
| sysfs `enabled` / `dpms` | `disabled` / `Off` | `disabled` / `Off` |

Hyprland's logical state remained off until user wake. Kernel-state snapshots were taken through the first **120 seconds**, not continuously throughout the entire idle interval. No relevant kernel errors were captured.

This ruled out merely drawing a black overlay in those snapshots. However, DRM software state alone cannot prove that the physical receiver or backlight is asleep.

### 3. The initial DisplayPort power-down write succeeded

The next trace observed `drm_dp_dpcd_write()` at DPCD address **`0x600` (`DP_SET_POWER`)**:

- `0x01`: D0, receiver power-up.
- `0x02`: D3, receiver power-down.
- For a one-byte write, `ret=1` means the helper completed the write successfully.
- Preserve raw values: `0x05` is a separate D3-with-AUX-on value, not ordinary D0.

Local capture: `result-dpms-capture/dpcd-power-Knp08owH/` (kernel `7.2.9`).

The Dell's initial D3 write succeeded. About **179 seconds later**, kernel workers sent both physical monitors a D3 → D0 → D3 sequence. For the Dell, the D0-to-D3 interval was approximately **64.5 ms**. Its normal Hyprland wake came about **42 seconds after that pulse**.

This ruled out a missing/failed initial D3 request. It did not yet identify the worker's caller or prove when the visible backlight changed.

### 4. Call stacks identified detection-time link training

Decisive local capture: **`result-dpms-capture/dpcd-power-dDp0tQXr/`**, kernel **`7.2.10`**.

The user reported seeing the backlight switch back on, then woke the desktop and stopped the script. The trace separates the unsolicited receiver wake from the later intentional wake.

Dell timeline, in `CLOCK_MONOTONIC` seconds:

| Time | Caller / operation | Result |
|---|---|---|
| `34597.023` | Hyprland: initial D3 | `ret=1` |
| `35313.298` | Kernel worker: D3 before verification | `ret=1` |
| `35313.328` | Kernel worker: D0 for verification | `ret=1` |
| `35313.393` | Kernel worker: D3 after verification | `ret=1` |
| `35325.662` | Hyprland: normal user-wake D0 | `ret=1` |

The unsolicited pulse happened nearly **12 minutes after initial power-off**, and approximately **12 seconds before normal wake**. There is no evidence of a fixed three-minute timer.

The unsolicited D0 stack was:

```text
drm_dp_dpcd_write
  dm_helpers_dp_write_dpcd
  core_link_write_dpcd
  dp_enable_link_phy
  dp_verify_link_cap_with_retries
  link_detect
  handle_hpd_irq_helper
  process_one_work
  worker_thread
```

The following D3 had the same verification path, through `dp_disable_link_phy` instead of `dp_enable_link_phy`.

The intentional wake used a different path:

```text
dp_enable_link_phy
  perform_link_training_with_retries
  enable_link_dp
  link_set_dpms_on
  amdgpu_dm_atomic_commit_tail
  ... Hyprland atomic ioctl ...
```

This distinguishes **hotplug-detection verification** from ordinary display activation. It also resolves the earlier competing hypothesis that the unexpected pulse might come from `wake_up_aux_channel()` error recovery.

The final capture's exit codes (`141` for the tracer pipeline, `130` for the log writer) followed the user's interruption. The preceding recorded writes and return values are present; those exit codes are not AMD power-write failures.

## Workaround and tradeoffs

File: [`hosts/minisforum-ai-x1/configuration.nix`](hosts/minisforum-ai-x1/configuration.nix), in the existing `boot.kernelParams` list:

```nix
# DC_SKIP_DETECTION_LT: HPD detection retrains sleeping DP links and wakes
# the Dell U2725QE backlight. Skip detection-time training, not normal wake.
"amdgpu.dcdebugmask=0x200000"
```

Verified against **Linux v7.2.10**:

1. `DC_SKIP_DETECTION_LT` is bit `0x200000`.
2. `amdgpu_dm_init()` maps it to `dc->debug.skip_detection_link_training`.
3. `should_verify_link_capability_destructively()` checks that flag. Setting it bypasses the destructive DP verification branch seen in the trace and uses non-destructive capability checking instead.
4. Normal activation still calls `perform_link_training_with_retries()`; that path is not disabled by this flag.

This does **not** disable HPD handling, DPMS, or the NPU driver. It avoids the demonstrated training pulse, not the underlying hotplug event.

### Scope / risk

- Applies to relevant AMD DP links on this host, including DP-1; it is not Dell-specific or limited to idle.
- Detection uses advertised/intersected capabilities instead of physically verifying the link. Detection-time bandwidth fallback is therefore lost; a marginal cable/link could fail a demanding mode even though ordinary modeset training remains.
- Verify both displays, normal wake, and 4K120 operation after applying it.
- The mask was **0** before this change. If other bits are added in future, combine them deliberately; do not overwrite unrelated bits or add competing copies of the parameter.
- The parameter is read-only at runtime (`0444`) and the flag is copied during display initialization. **A reboot is required**; writing sysfs or rebuilding alone is not an activation method.

### Validation performed

- `just build`: **passed**; the system and boot configuration were built without activation.
- `nix eval --json .#nixosConfigurations.mini.config.boot.kernelParams --no-update-lock-file`: confirmed `amdgpu.dcdebugmask=0x200000` in the result.
- `git diff --check`: passed at the workaround change.
- Existing unrelated Home Manager/Stylix version and renamed-option warnings remained.

### Apply and verify (user action)

From the repository:

```sh
just switch_on_boot
```

Then reboot when convenient. The agent did not execute this activation step.

After reboot, check:

```sh
uname -r
cat /proc/cmdline
cat /sys/module/amdgpu/parameters/dcdebugmask
```

For this bit alone, the mask should be `2097152` (decimal `0x200000`). Let the Dell remain in standby for **15–20 minutes after screen-off**, then verify normal wake and 4K120 operation. Ideally, repeat the power-write trace and confirm the detection-LT pulse is absent.

**Post-reboot physical result: not yet recorded.**

To roll back, remove only this parameter from the host configuration, rebuild/install for next boot, and reboot. Keep unrelated kernel settings and the latest-kernel/NPU choice intact.

## Reproduction tools and local evidence

### Passive logical/KMS capture

[`scripts/capture-dpms.sh`](scripts/capture-dpms.sh):

```sh
nix shell nixpkgs#drm_info --command bash scripts/capture-dpms.sh result-dpms-capture
```

It records baseline, logical DPMS transitions, kernel connector/CRTC state at off-state checkpoints, wake, and relevant logs. It is read-only and bounded to approximately 30 minutes, plus final collection. `--snapshot` performs a single capture.

### Actual DPCD writes and caller stacks

[`scripts/trace-dpms-power.sh`](scripts/trace-dpms-power.sh):

```sh
nix shell nixpkgs#bpftrace --command bash scripts/trace-dpms-power.sh result-dpms-capture
```

Requires `sudo`. It attaches entry/return probes to `drm_dp_dpcd_write`, records only writes beginning at address `0x600`, and includes caller stacks. It observes existing writes; it does not send AUX reads/writes, force DPMS, or change display modes.

The trace is bounded to **20 minutes from attachment**, including the idle countdown. With a 10-minute idle timeout, a pulse 12 minutes after screen-off would fall outside that window. For the decisive test the user temporarily used a 30-second Noctalia timeout. When reproducing, deliberately arrange a sufficient observation window and restore any temporary idle setting afterward.

bpftrace 0.25.1 emitted harmless `Return value discarded` warnings for map `delete()` calls. `Attached 3 probes` was expected (entry, return, END). Negative DPCD return values, failed memory-read warnings, failed attachment, or lost events must not be interpreted as successful power-down.

### Evidence locations

- `result-dpms-capture/dpms-dNitoc4N/`: logical/KMS off-state capture, 2026-10-13 morning.
- `result-dpms-capture/dpcd-power-Knp08owH/`: first observed delayed D0 pulse, without stacks, kernel 7.2.9.
- `result-dpms-capture/dpcd-power-dDp0tQXr/`: decisive HPD/link-verification call stacks and visual observation, kernel 7.2.10.

**These directories match the repository's `result-*` ignore rule and are not preserved by Git.** The key results are reproduced above so this document remains useful if local captures are deleted. Archive the raw captures separately if needed for an upstream report; review them for identifying information first.

Connector IDs, worker TIDs and AUX device numbers are boot-specific. During the investigation:

- DP-3 had connector ID 472, normally attached to CRTC 437.
- DP-1 had connector ID 458, normally attached to CRTC 432.
- `/sys/class/drm/card0-DP-3/drm_dp_aux2/name` identified the Dell's AUX as `AMDGPU DM aux hw bus 3`.

Recheck mappings after a reboot rather than hardcoding these IDs. SUNSHINE is a compositor headless output, not a physical DRM connector.

## Discarded or unproven explanations

- **60 Hz / bandwidth alone:** did not fix standby.
- **Noctalia fade or logical DPMS alone:** kernel off-state capture and D3 traces demonstrate that power-down progressed beyond a black overlay.
- **`hyprmoncfgd` refresh reconciliation:** interfered with early 60 Hz testing, but was not active during the decisive sleeping interval; the unsolicited D0 came from a kernel worker.
- **Generic PSR-disable advice:** connectors reported PSR unsupported; not justified.
- **Missing initial D3 write / silently failed write:** ruled out for traced occurrences by `size=1`, `byte0=0x02`, `ret=1`.
- **AUX-error recovery pulse:** plausible before stacks, but the decisive stack showed detection-time verification instead.
- **MST remote-sink power-down patch:** no DRM `PATH` property indicated an active MST sink here, and the observed path was ordinary DP detection training. Monitor MST capability alone does not establish MST topology.
- **Aquamarine DPMS/page-flip bugs:** a relevant upstream fix exists, but the demonstrated unsolicited pulse was inside AMD's HPD detection path. Upgrading Aquamarine was not established as the fix for this occurrence.
- **No kernel error means hardware slept:** false; the power writes succeeded while the visible result was still wrong.
- **D3 acknowledgement proves the monitor's backlight is off:** false; it establishes completion of the DPCD helper write, not physical standby.

## Source references

Exact kernel sources used to verify the targeted control and its scope:

- [v7.2.10: `DC_SKIP_DETECTION_LT` definition](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/include/amd_shared.h#L415-L418)
- [v7.2.10: mapping the mask to `skip_detection_link_training`](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/display/amdgpu_dm/amdgpu_dm.c#L2258-L2259)
- [v7.2.10: destructive detection verification gate](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/display/dc/link/link_detection.c#L894-L960)
- [v7.2.10: normal DP enable and fallback responsibilities](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/display/dc/link/link_dpms.c#L2030-L2126)
- [v7.2.10: normal link training](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/display/dc/link/protocols/link_dp_training.c#L1620-L1705)
- [v7.2.10: read-only `dcdebugmask` module parameter](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/amdgpu/amdgpu_drv.c#L863-L868)

Related, but not established as fixes for this case:

- [Aquamarine PR #312: deterministic page-flip scheduling and DPMS cleanup](https://github.com/hyprwm/aquamarine/pull/312)
- [Dell KB 000356362: U2725QE/U3225QE firmware issues](https://www.dell.com/support/kbdoc/en-us/000356362/dell-ultrasharp-monitors-may-exhibit-various-issues). This did not establish a firmware fix for this exact symptom, and the Dell's own firmware version was not recorded.
