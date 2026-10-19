import { randomUUID } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const stateDir = process.env.OPENCLAW_STATE_DIR;
if (!stateDir) {
  throw new Error("OPENCLAW_STATE_DIR must point to the persistent state mount");
}

const configPath = path.join(stateDir, "openclaw.json");
if (!fs.existsSync(configPath) || fs.statSync(configPath).size === 0) {
  const temporaryPath = `${configPath}.seed-${randomUUID()}`;
  try {
    fs.writeFileSync(temporaryPath, fs.readFileSync("/etc/openclaw/defaults.json"), {
      flag: "wx",
      mode: 0o600,
    });
    fs.renameSync(temporaryPath, configPath);
  } finally {
    fs.rmSync(temporaryPath, { force: true });
  }
}

// Use the host-aware npm installer so it records provenance and enables the plugin.
const installation = spawnSync(
  process.execPath,
  [
    "/app/openclaw.mjs",
    "plugins",
    "install",
    "npm:@openclaw/signal",
    "--force",
    "--accept-capabilities",
  ],
  { stdio: "inherit", timeout: 10 * 60 * 1000 },
);
if (installation.error || installation.status !== 0) {
  console.error("Signal npm plugin installation failed", installation.error ?? "");
  process.exit(installation.status ?? 1);
}

// Preserve the image's Doctor/migration entrypoint before starting the gateway.
process.execve(
  process.execPath,
  [
    process.execPath,
    "/app/docker-entrypoint.mjs",
    process.execPath,
    "/app/openclaw.mjs",
    "gateway",
    "--bind",
    "lan",
    "--port",
    "18789",
  ],
  process.env,
);
