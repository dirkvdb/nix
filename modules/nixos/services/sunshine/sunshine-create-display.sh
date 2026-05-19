WIDTH=${SUNSHINE_CLIENT_WIDTH:-1920}
HEIGHT=${SUNSHINE_CLIENT_HEIGHT:-1080}
FPS=${SUNSHINE_CLIENT_FPS:-60}

# Ensure the headless output exists (no-op if already present)
hyprctl output create headless SUNSHINE 2>/dev/null || true

# Configure resolution, placement off-screen to avoid overlap, and scale
hyprctl keyword monitor "SUNSHINE,${WIDTH}x${HEIGHT}@${FPS},auto,1"
