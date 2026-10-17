# Dell U2725QE backlight returns during display sleep

Investigation recorded: **2026-10-13**. Host: **`mini`** (`hosts/minisforum-ai-x1`).

**Update 2026-10-14:** a hard hang was captured on the **standard 7.2.10 kernel**, with the backlight workaround already active, after NordVPN and brightness control were re-enabled. The journal confirms a graphics-ring timeout, failed GPU recovery, and CPU stalls. The earlier observations do **not** establish that hard hangs are exclusive to CachyOS. See [Hard-hang follow-up](#hard-hang-follow-up-2026-10-14).

**Update 2026-10-17:** another unresponsive-system incident required a manual reset. Brightness control is now disabled, but this boot has **no retained GPU/SMU/RCU failure signature**. The user confirmed that **ping worked but SSH did not**. Its journal ends with successful activity the previous evening; the hang time and failed subsystem remain unknown. Local diagnostics, a remote recorder and a boot-time GFXOFF-off trial are now prepared, **not activated**. See [October 17 recurrence](#hard-reset-recurrence-2026-10-17).

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
| Standard latest `7.2.10` | Hard hang captured 2026-10-14 | Backlight tracing identified detection-time training; the later GPU hang occurred with that workaround active |
| CachyOS `7.2.8-cachyos-lto` | Reproducible in earlier tests | Keep disabled; whether the old hangs share the later GPU failure mechanism is unknown |

The configuration retains:

```nix
local.system.kernel = {
  cachyos.enable = false;
  useLatest = true;
};
```

Both previously compared standard kernels loaded DMUB firmware `0x09005300`. Display Core versions were `3.2.351` on the stable kernel and `3.2.384` on latest `7.2.9`. This is GPU firmware information, **not the Dell monitor's firmware version**.

The old CachyOS hangs included a recorded hardware-watchdog reset. Neither that reset nor the earlier I/O-pressure measurements establish that those hangs share a cause with the backlight wake or the later standard-kernel GPU hang.

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

## Hard-hang follow-up: 2026-10-14

### Incident and confirmed failure

The user re-enabled NordVPN and brightness control, worked on another PC connected to the same Dell monitor, then found `mini` unresponsive and performed a hard reset.

Failed boot ID: **`3030d11c31d442db967d7c674c4bbe95`**. It started 2026-10-13 at 20:11:30 CEST. Last recorded events were 2026-10-14 at **16:33:48 CEST**; the next boot began at 17:40:03.

The failed boot was **standard Linux 7.2.10**, not CachyOS. Its recorded command line already contained `amdgpu.dcdebugmask=0x200000`.

| Time (CEST) | Journal evidence |
|---|---|
| 16:33:19 | `Fence fallback timer expired on ring gfx_0.0.0` |
| 16:33:21 | `Dumping IP State` |
| 16:33:27–42 | Repeated `SMU: No response msg_reg: 1a resp_reg: 0` and `Failed to disable gfxoff!` |
| 16:33:42 | RCU stall on CPU 2; `hyprmoncfgd` thread blocked in `madvise` → TLB flush → `smp_call_function_many_cond` |
| 16:33:42 | `ring gfx_0.0.0 timeout`; affected submission identified as `.noctalia-wrapp`, thread `noctalia:cs0` |
| 16:33:44 | `MES failed to respond to msg=RESET`, reset timeout `-110`, ring reset failed, then `GPU reset begin!` |
| 16:33:48 | `watchdog: BUG: soft lockup - CPU#3 stuck for 26s! [jemalloc_bg_thd:2961]` |

**Confirmed:** a GPU timeout with unresponsive recovery/firmware paths and CPU stalls. **Unconfirmed:** the event that initially triggered the GPU failure, and whether the earlier CachyOS hangs were the same failure.

Important interpretation limits:

- The timeout names the GPU submission owner; it does not prove a Noctalia application bug caused the GPU to hang.
- The RCU trace names a task caught waiting for a CPU TLB shootdown; it does not establish `hyprmoncfgd` as the cause.
- In kernel 7.2.10, the timed-out-job handler performs its device dump **before printing** the ring-timeout/process lines. The dump itself requests GFXOFF disable. The `Failed to disable gfxoff!` messages can therefore be consequences of an already-unresponsive GPU, not proof that GFXOFF initiated the failure.
- The CPFW pipe-reset warning describes an unsupported recovery path in this source; it does not by itself establish that installed firmware is obsolete.
- There were no recorded DDC/I²C failure messages around the crash, nor recorded NFS-server-not-responding, NVMe timeout/reset, or OOM messages explaining it. Missing messages do not prove those subsystems were uninvolved.
- The earlier detection-training workaround is not a general GPU-hang fix and does not disable GFXOFF.

### Brightness-control implementation actually present

The brightness module couples `local.system.display.brightnesscontrol.enable` to Noctalia's `brightness.enable_ddcutil`. Re-enabling it therefore enables userspace DDC traffic through AMD's DisplayPort AUX implementation.

After the reset:

- `ddcutil` was **2.2.7**.
- Bus `i2c-13` identified itself as `AMDGPU DM aux hw bus 3` (Dell DP-3).
- An I²C client named `ddcci` existed at `13-0037`, but it had **no bound driver**.
- Neither `ddcci` nor `ddcci_backlight` was loaded; `/sys/class/backlight` was empty.
- The failed boot likewise logged client instantiation, without recorded driver/backlight initialization. That supports, but cannot conclusively reconstruct, the historical binding state.

Thus an active kernel-ddcci/userspace-ddcutil conflict was **not demonstrated**. The attachment service's success and `options ddcci delay=200` do not prove that a kernel backlight driver is functioning. Noctalia's own DDC calls use their own timing arguments; the module delay does not control them.

Source inspection found Noctalia DDC detection/query work triggered by startup, configuration/output changes and monitor-control interactions, not a periodic DDC refresh timer. DDC remains a plausible input-switch/hotplug trigger to isolate, not a proven explanation for the graphics-ring failure.

### I/O-pressure and reset diagnostics gap

The previously added diagnostics had been removed from the configuration before this incident:

- `io-pressure-snapshot.service` was absent, with no entries for the failed boot.
- sysstat collection was inactive; no `sa14` file existed. The newest retained activity file stopped on October 13 at 19:53.
- Runtime hardware watchdog was disabled (`RuntimeWatchdogUSec=0` on the new boot), and the current host configuration no longer set it.

There is therefore **no captured I/O-pressure history for this incident** to compare with the GPU failure. The old high-pressure measurements remain observations, not proof of a storage/NFS cause or a common cause across all hangs.

The new boot recorded an ACPI power-state transition reset reason, not a hardware-watchdog-expired reason. A GPU devcoredump was created during the failed boot, but no such dump remained in sysfs after reboot.

### Recommended isolation step at the time

This was the recommendation on October 14. By October 17 the host's shared brightness-control option had been disabled; additional performance settings had also changed. That is not the exact single-variable experiment described below.

Change **only Noctalia's `brightness.enable_ddcutil` to false**, holding NordVPN, the kernel, the display workaround and the attachment service fixed. Use a fresh Noctalia session with DDC disabled; reloading cannot retract a command already stuck in kernel I/O.

This isolates the active brightness-DDC implementation without attempting a live kernel-driver unbind. A stable result would implicate DDC-triggered activity as a contributor, not establish a dual-driver conflict or identify the underlying GPU defect. Do not simultaneously disable NordVPN or add GPU power-management masks, because that would destroy the comparison.

Restore selected crash/I/O diagnostics only as a deliberate follow-up; none were restored automatically during this investigation. No service, display state, kernel setting or running configuration was changed in the follow-up analysis.

For revisiting the raw journal while it is retained:

```sh
journalctl -k -b 3030d11c31d442db967d7c674c4bbe95 --no-pager \
  --since '2026-10-14 16:32:00' --until '2026-10-14 16:34:00'
```

A closely matching Strix Point/890M display-off GPU/SMU failure is reported in [AMD issue #5822](https://gitlab.freedesktop.org/drm/amd/-/issues/5822), on a different machine/kernel. It is a useful comparison, **not a confirmed diagnosis or verified fix** for `mini`.

Relevant source checks:

- [7.2.10: timed-out-job dump and process reporting](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/amdgpu/amdgpu_job.c#L37-L170)
- [7.2.10: GFXOFF-disable requests during the graphics IP dump](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/amdgpu/gfx_v11_0.c#L7178-L7249)

## Hard-reset recurrence: 2026-10-17

The user reported needing another hard reset in the morning. Failed boot ID: **`9001e089eb804f02881f61d9ab709eb9`**. It started October 16 at **20:49:39 CEST**; the next boot began October 17 at **08:34:58 CEST**.

### Observed configuration and chronology

- Standard kernel **7.2.10**, CachyOS disabled, detection-training workaround `amdgpu.dcdebugmask=0x200000` active.
- Brightness control is now **disabled** in the host configuration. The inspected rendered Noctalia configuration contains `enable_ddcutil = false`. The failed boot used the same NixOS init generation as the new boot, and its inspected Noctalia log did not select a DDC backend.
- NordVPN remains enabled.
- Additional performance settings are now active: `preempt=full`, irqbalance and ananicy. They were not present in the October 14 baseline, so this was not a strictly isolated DDC-only A/B.
- **21:00:32 on October 16:** Noctalia requested screen-off.
- **21:00:35:** `hyprmoncfgd` detected sleep and paused switching.
- **21:09:01:** `sd_mod` loaded successfully during fwupd startup; `SCSI subsystem initialized` was its kernel message, not a recorded disk error.
- **21:09:02.127:** fwupd metadata refresh completed successfully; this was the last retained journal record.
- No later wake, orderly shutdown, GPU timeout, SMU failure, RCU stall, blocked-task report, NFS nonresponse, NVMe timeout/reset or OOM event was retained for this boot.

**The last journal timestamp is not the established hang time.** Neither successful fwupd refresh nor SCSI module initialization identifies the cause. Silence afterward could reflect a later unrecorded hang, failed logging, or simply an interval without retained messages.

The earlier October 14 GPU hang remains confirmed, but **this recurrence cannot yet be classified as the same fault**. The user subsequently confirmed that **ping still worked, but SSH was not possible**. This demonstrates partial network/kernel responsiveness, not working userspace or a proven total CPU freeze. VPN policy, an SSH-specific problem, blocked userspace and kernel stalls still need distinguishing. The brightness-off configuration has not prevented the reported symptom; that does not by itself identify which component failed this time.

### Remaining evidence gap and next tests

At inspection, before the changes below, the quiet I/O recorder and sysstat collection were absent. `RuntimeWatchdogUSec=0` meant no systemd-managed hardware-reset watchdog. The NMI detector is a separate mechanism and is enabled (`kernel.nmi_watchdog=1`). There is no new historical I/O-pressure capture to recover.

Before another reset, a prevalidated LAN SSH path from the other PC would help separate a display/input failure from a deeper lockup. Successful SSH commands establish that userspace still runs; failed SSH alone does not prove a CPU freeze because VPN/network policy can also block access. A bounded remote heartbeat/PSI recording would preserve evidence on the other PC rather than depend entirely on local journal persistence. The same instrumentation should be used in any subsequent A/B because it can perturb idle behavior.

A **GFXOFF-off experiment** remains a reasonable hypothesis test based on the October 14 GPU/SMU incident, **not a confirmed fix or diagnosis of this silent recurrence**. The actual inspected power-feature mask is `0xfff7bfff`; clearing only `PP_GFXOFF_MASK` (`0x8000`) yields `0xfff73fff`. For this kernel/current mask, the boot parameter is `amdgpu.ppfeaturemask=0xfff73fff`. It is separate from `dcdebugmask`, may increase idle power, and must not be carried forward blindly if the kernel/default mask changes. It is now configured for the next user-applied boot, not applied to the running GPU.

Source verification: [7.2.10 power-feature bits](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/include/amd_shared.h#L231) and [the `ppfeaturemask` parameter](https://github.com/gregkh/linux/blob/v7.2.10/drivers/gpu/drm/amd/amdgpu/amdgpu_drv.c#L494-L500). A fresh check of AMD issue #5822 found no accessible confirmed fix; its discussion was not fully accessible, so an upstream resolution cannot be asserted.

### Authorized follow-up: prepared diagnostics and GFXOFF trial

After the ping-only clarification, the user authorized the recommended actions. The configuration now imports `hosts/minisforum-ai-x1/freeze-diagnostics.nix`, using `hosts/minisforum-ai-x1/io-pressure-snapshot.sh`. No running service, display state or GPU setting was changed by the agent; activation and reboot remain user actions.

The prepared configuration adds:

- **Quiet I/O snapshots:** sample `/proc/pressure/io` every 30 seconds; log only when `some avg10 >= 5%`, with a 120-second cooldown after each snapshot. Capture D-state thread names/wait channels/kernel stacks, CPU/memory/I/O PSI, `iostat`, `pidstat`, `vmstat`, and NFS client counters. Each section has a 10-second budget. It does not inspect process arguments/environments, probe GPU/DDC state, or traverse NFS files. Elevated I/O PSI means tasks are stalled, not necessarily that a physical disk is the cause.
- **sysstat history:** collect every minute; the package's default retention is seven days. This intentionally retains a small baseline even when the threshold-triggered journal recorder is quiet.
- **Journal flushing:** `SyncIntervalSec=30s` reduces the normal persistence window. It cannot guarantee writes during a storage/kernel stall and adds modest write activity.
- **Best-effort crash evidence:** enable EFI pstore writes with `efi_pstore.pstore_disable=N`, report hung tasks after 60 seconds, and request all-CPU backtraces on hung-task/soft-lockup/hard-lockup reports. SysRq mask `24` permits diagnostic dumps and sync, not keyboard-triggered kill/reboot. Pstore depends on firmware support and an oops/panic; a silent hang or hard reset may leave nothing.
- **Hardware watchdog:** `RuntimeWatchdogSec=1min`, fed by systemd PID 1, not by the recorder. Upon activation, a supported watchdog can reset the machine if systemd stops feeding it, potentially losing unsaved work. A GPU hang with healthy PID 1 may keep the watchdog fed; recovery is not guaranteed. No panic-on-lockup behavior was added.
- **Controlled GPU power trial:** `amdgpu.ppfeaturemask=0xfff73fff` clears only GFXOFF from the inspected mask. Latest standard kernel, Lemonade/NPU support, `amdgpu.dcdebugmask=0x200000`, DDC-off, NordVPN and the existing performance settings are retained. This is not a broad power-management disable.

#### Apply and verify (user action)

From this repository on `mini`, prepare the next boot and then reboot when ready:

```sh
just switch_on_boot
sudo reboot
```

After boot, verify the actual settings rather than assuming the build activated them:

```sh
uname -r
cat /proc/cmdline
cat /sys/module/amdgpu/parameters/ppfeaturemask
systemctl show --property=RuntimeWatchdogUSec
systemctl status io-pressure-snapshot.service sysstat-collect.timer --no-pager
journalctl -b --no-pager -g 'watchdog|pstore'
```

Expected AMD parameters are `amdgpu.dcdebugmask=0x200000` and `amdgpu.ppfeaturemask=0xfff73fff`; the module's effective power-feature mask should be `0xfff73fff`. The manager should report a one-minute runtime watchdog; check its boot messages for actual hardware selection. A healthy I/O recorder produces **no snapshots** until the threshold is met.

#### Record from the other PC

`scripts/watch-mini.py` must run on **another PC**, with Python 3 and native SSH/ping (Linux/macOS; use WSL on Windows). First verify key-based LAN SSH while `mini` is healthy and NordVPN is in the intended test state, and establish/trust its host key normally. The recorder refuses unknown/changed host keys or interactive authentication; do not weaken those checks to make the test work.

With this script available on that PC:

```sh
ssh dirk@mini.fritz.box true
python3 scripts/watch-mini.py dirk@mini.fritz.box result-mini-watch --hours 12
```

The mandatory SSH preflight must succeed before recording begins. If using an SSH alias that is not also a resolvable LAN name, add `--ping-host mini.fritz.box` (or the verified LAN IP). It opens a persistent, bounded remote sampling session, recording uptime/boot ID, CPU/memory/I/O PSI, selected memory/cgroup counters and D-state process names/wait channels every 30 seconds. Independent ping checks run every 10 seconds; SSH reconnects are attempted after failures. No root, process arguments/environments, or GPU probes are used.

Two timestamped private logs are stored **on the other PC**, each capped at 16 MiB. The recorder stops after 12 hours by default, when either byte cap is reached, or on Ctrl-C; remote sampling also has a time limit. Increase `--hours` if the observation window crosses the next morning. SSH activity can perturb idle behavior, so use the **same instrumentation for baseline and trial**.

#### Automatic recorder on mediastation

`hosts/mediastation/watch-mini.nix` now configures **`watch-mini.service`** on `mediastation`, using the same recorder. It starts at boot after `network-online.target`, runs as `dirk`, records 24-hour sessions, and restarts after one minute on completion, byte-cap exhaustion or failure. Failed initial SSH preflights are therefore retried rather than permanently disabling monitoring. Ping recording begins only after the first healthy SSH preflight; once that has succeeded in a session, ping continues independently through SSH failures.

Logs stay on **mediastation's local disk** in **`/var/lib/watch-mini/`**, not on an NFS share or on `mini`. The directory is private (`0700`), logs are `0600`, and each of the two logs per session remains capped at 16 MiB. Systemd-tmpfiles cleans files unused for seven days; this is age-based retention, not a hard aggregate byte quota. Standard output/errors go to the `watch-mini` journal, while the detailed samples go to the files. State is retained across service restarts and reboots.

The service uses `dirk`'s existing SSH configuration and identity files, **not an interactive session's SSH agent**. Mediastation does not use KeePass to populate an agent. The user supplied the public key `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4oqfUXoR8JbTTg8dY00q4ScAvCDje2n/KGnkahHsJ7 mediastation-mini-monitor`, whose matching private key belongs at `/home/dirk/.ssh/id_ed25519` on mediastation only and must be usable unattended. The public key is now authorized in mini's host configuration with `restrict`, disabling PTY allocation, forwarding and user SSH rc execution; it still permits commands as `dirk`, not only the sampler. Existing authorized keys are retained. No private key is generated, copied or stored in Nix by the agent. After applying mini's updated configuration, test from mediastation with no inherited agent:

```sh
sudo -Hu dirk env -u SSH_AUTH_SOCK -u SSH_AGENT_PID \
  ssh -T -o BatchMode=yes -o StrictHostKeyChecking=yes -o ControlPath=none \
  dirk@mini.fritz.box true
```

The host's Ed25519 public key is pinned in mediastation's system-wide known hosts, verified directly on `mini` during implementation: **`SHA256:qw9mWSIxngAh70r6v341c9nmmbjDmJyzshksv34v5qY`**. A reinstall/key rotation must be verified independently before updating the pin; strict checking is not disabled. LAN routing/firewall access with NordVPN enabled must also work. The recorder neither changes VPN policy nor opens an inbound port on mediastation.

After the user deploys the updated mediastation configuration, inspect it there:

```sh
systemctl status watch-mini.service --no-pager
journalctl -u watch-mini.service -n 30 --no-pager
ls -lt /var/lib/watch-mini/
```

Validation: the complete mediastation system built successfully with `nix build .#nixosConfigurations.mediastation.config.system.build.toplevel --no-update-lock-file --out-link result-mediastation --print-build-logs`. The generated unit was inspected, the current host's `just build` passed, and all 14 recorder unit tests passed again. Existing unrelated version/deprecation warnings remain. Live SSH authentication from mediastation and the running service have not been verified. No service was activated or started by the agent. Keep this same service running for both baseline and GFXOFF-off observations, since monitoring activity can change idle behavior.

#### Evidence after another incident

Keep the other PC's two logs, note local time and whether ping/SSH worked, and collect the previous boot's local records after recovery:

```sh
journalctl -b -1 -u io-pressure-snapshot.service --no-pager
journalctl -k -b -1 --no-pager
ls -l /var/log/sa
sudo ls -l /sys/fs/pstore /var/lib/systemd/pstore
```

Use `sar -A -f /var/log/sa/saDD` with the actual retained file/day, not an assumed crash timestamp. Systemd may move pstore records into `/var/lib/systemd/pstore`. No GPU devcoredump archiver was added; a transient GPU dump can still be lost across reboot.

For a controlled baseline, remove **only** `amdgpu.ppfeaturemask=0xfff73fff`, rebuild and boot, keeping the diagnostics, DDC/VPN/performance settings, workload, and input-switch/idle sequence identical. Restore the parameter for the trial. Do not toggle GFXOFF live via debugfs. If the trial helps, that implicates a power-state path but does not establish the original trigger or prove an upstream fix. A kernel update requires checking its default mask and re-evaluating this experiment.

Validation on October 17: **`just build` passed** without activating the configuration. The remote recorder's **14 hermetic unit tests passed** (`nix shell nixpkgs#python3 --command python3 -B scripts/test_watch_mini.py`); Bash syntax and ShellCheck passed for the local helper. Full host evaluation confirmed both AMD parameters, sysstat's one-minute cadence, the one-minute watchdog setting, diagnostic sysctls, and the recorder unit. Existing unrelated deprecation/version-mismatch evaluation warnings remain. There is **no post-boot stability result yet**.

A direct, unprivileged packaged-helper `--once` test also exercised the real threshold-triggered path. Around **09:10 CEST on October 17**, after the build, I/O PSI was already high (`some avg10=75.86%`, `full avg10=71.31%`), with negligible CPU/memory PSI. The one-second `iostat` interval reported no active device and `pidstat` identified no active disk-I/O producer; there were no D-state threads at that snapshot instant. A follow-up found D-state `kworker/u82:3+events_unbound` (PID/TID `41031`), but its stack could not be collected because non-interactive sudo was unavailable. These short observations do **not** identify the producer, establish a storage/GPU cause, or reconstruct the overnight failure. The future systemd recorder runs as root and attempts kernel stacks when blocked threads coincide with a sample; no service was started for this one-shot test.

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
