{
  lib,
  pkgs,
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  inherit (config.local) theme;
  inherit (config.lib.stylix) colors;
  isLinux = pkgs.stdenv.isLinux;
  isDesktop = config.local.desktop.enable;
  mkUserHome = mkHome user.name;
in
{
  config = lib.mkIf (isLinux && isDesktop) (mkUserHome {
    xdg.configFile."nmrs/style.css".text = ''
      /* Stylix / ${theme.name} theme for nmrs-gui                          */
      /* This is the full stylesheet — variable definitions + structural CSS */

      window.light-theme {
        --bg-primary:         #${colors.base07};
        --bg-secondary:       #${colors.base06};
        --bg-tertiary:        #${colors.base05};
        --text-primary:       #${colors.base00};
        --text-secondary:     #${colors.base01};
        --text-tertiary:      #${colors.base02};
        --border-color:       #${colors.base05};
        --border-color-hover: #${colors.base04};
        --accent-color:       #${colors.base0D};
        --success-color:      #${colors.base0B};
        --warning-color:      #${colors.base0A};
        --error-color:        #${colors.base08};
      }

      window,
      window.dark-theme {
        --bg-primary:         #${colors.base00};
        --bg-secondary:       #${colors.base01};
        --bg-tertiary:        #${colors.base02};
        --text-primary:       #${colors.base05};
        --text-secondary:     #${colors.base04};
        --text-tertiary:      #${colors.base03};
        --border-color:       #${colors.base02};
        --border-color-hover: #${colors.base03};
        --accent-color:       #${colors.base0D};
        --success-color:      #${colors.base0B};
        --warning-color:      #${colors.base0A};
        --error-color:        #${colors.base08};
      }

      /* Window */
      window {
        background-color: var(--bg-primary);
        color: var(--text-primary);
        font-family: "${theme.uiFont}";
        font-size: ${toString theme.uiFontSize}pt;
      }

      /* Header */
      headerbar {
        background: var(--bg-secondary);
        color: var(--text-primary);
        border-bottom: 1px solid var(--border-color);
      }

      /* Switch */
      switch {
        background-color: var(--bg-tertiary);
      }
      switch:checked {
        background-color: var(--accent-color);
      }

      /* Wi-Fi label */
      .wifi-label {
        font-weight: 600;
        color: var(--text-primary);
      }

      /* List */
      list {
        background: var(--bg-primary);
        border: none;
      }
      list > row {
        background: transparent;
        border: none;
        padding: 0;
      }
      list > row:selected {
        background: var(--accent-color);
        color: var(--bg-primary);
      }

      /* Entry fields */
      .pw-entry {
        background-color: transparent;
        color: var(--text-primary);
        border-color: transparent;
      }

      /* Network selection */
      .network-selection {
        padding: 6px 10px;
        margin: 2px 0;
        background: var(--bg-secondary);
        border: 1px solid var(--border-color);
      }
      .network-selection:hover {
        background: var(--bg-tertiary);
        border-color: var(--border-color-hover);
        transition: background 150ms ease, border-color 150ms ease;
      }
      .network-selection.connected {
        background: color-mix(in srgb, var(--success-color) 15%, transparent);
        border-color: color-mix(in srgb, var(--success-color) 30%, transparent);
      }
      .network-selection.connected:hover {
        background: color-mix(in srgb, var(--success-color) 20%, transparent);
        border-color: color-mix(in srgb, var(--success-color) 40%, transparent);
      }
      .network-selection label {
        font-size: 14px;
        color: var(--text-primary);
      }
      .connected-label {
        font-size: 12px;
        color: var(--success-color);
        font-style: italic;
        margin-left: 8px;
        opacity: 0.9;
      }

      /* Network quality labels */
      label.network-good { color: var(--success-color); }
      label.network-okay { color: var(--warning-color); }
      label.network-poor { color: var(--error-color); }

      /* Network page */
      .network-page {
        background: var(--bg-primary);
        padding: 16px 20px;
        color: var(--text-primary);
        border: none;
      }

      /* Back button */
      .back-button {
        background: none;
        border: none;
        color: var(--text-tertiary);
        font-weight: 500;
        font-size: 13px;
        padding: 4px 0;
      }
      .back-button:hover { color: var(--text-primary); }

      /* Network details */
      .network-icon { color: var(--text-primary); }
      .network-title {
        font-size: 18px;
        font-weight: 600;
        color: var(--text-primary);
        margin-bottom: 4px;
      }
      .network-arrow { color: var(--text-primary); }
      .network-info {
        margin-top: 14px;
        padding-left: 6px;
      }
      .info-row { padding: 2px 0; }
      .info-value {
        color: var(--text-primary);
        font-size: 14px;
        font-weight: 500;
      }

      /* Section headers */
      .section-header {
        font-weight: 600;
        font-size: 13px;
        text-transform: uppercase;
        border-bottom: 1px solid var(--border-color);
        padding-bottom: 4px;
        margin-bottom: 6px;
        color: var(--text-secondary);
        letter-spacing: 0.5px;
      }

      /* Info keys and values */
      .basic-key,
      .info-label {
        font-weight: 600;
        font-size: 13px;
        color: var(--text-tertiary);
        margin-bottom: 2px;
        text-decoration: underline;
      }
      .basic-value,
      .info-value {
        font-size: 14px;
        color: var(--text-primary);
        font-weight: 500;
        margin-bottom: 8px;
      }

      /* Divider */
      .divider {
        margin-top: 10px;
        margin-bottom: 10px;
        opacity: 0.25;
        border-bottom: 1px solid var(--border-color);
      }

      /* Wi-Fi secure/open */
      .wifi-secure { color: var(--text-primary); }
      .wifi-open   { color: var(--text-primary); }

      /* Loading spinner */
      .loading-spinner {
        margin-top: 12px;
        margin-bottom: 12px;
        opacity: 0.6;
      }

      /* Forget button */
      .forget-button {
        font-size: 0.85em;
        opacity: 0.7;
        padding: 2px 6px;
        border-radius: 6px;
      }
      .forget-button:hover { opacity: 1; }

      /* Refresh button */
      .refresh-btn {
        background: none;
        border: none;
        color: var(--text-tertiary);
        font-weight: 500;
        font-size: 13px;
        padding: 4px 0;
      }
      .refresh-btn:hover { color: var(--text-primary); }

      /* Theme toggle */
      .theme-toggle-btn {
        background: none;
        border: none;
        color: var(--text-tertiary);
        padding: 4px 8px;
        opacity: 0.7;
        transition: opacity 150ms ease, color 150ms ease;
      }
      .theme-toggle-btn:hover {
        opacity: 1;
        color: var(--text-primary);
      }

      /* Dropdown */
      .dropdown {
        background: var(--bg-secondary);
        border: none;
        color: var(--text-primary);
        padding: 6px 12px;
        font-size: 13px;
      }
      .dropdown button {
        background: var(--bg-secondary);
        border: none;
        color: var(--text-primary);
        padding: 6px 12px;
        font-size: 13px;
      }
      .dropdown button label {
        color: var(--text-primary);
      }
      .dropdown button:hover {
        background: var(--bg-tertiary);
        border-radius: 0;
      }

      /* Popover */
      popover.background,
      popover contents {
        background: var(--bg-secondary);
        border-radius: 0;
      }
      popover row {
        background: var(--bg-secondary);
        color: var(--text-primary);
        border-radius: 0;
      }
      popover row:hover {
        background: var(--bg-tertiary);
      }
      popover row:selected {
        background: var(--accent-color);
        color: var(--bg-primary);
      }
      popover row label {
        color: var(--text-primary);
      }

      /* Wired device styles */
      .wired-section-header,
      .wireless-section-header {
        font-weight: 700;
        font-size: 14px;
        text-transform: uppercase;
        color: var(--text-secondary);
        letter-spacing: 0.8px;
        opacity: 0.8;
      }

      .wired-devices-list {
        background: var(--bg-primary);
        margin-bottom: 8px;
      }

      .wired-icon {
        color: var(--success-color);
        opacity: 0.8;
        margin-left: 6px;
      }

      .device-separator {
        background: var(--border-color);
        opacity: 0.5;
      }
    '';
  });
}
