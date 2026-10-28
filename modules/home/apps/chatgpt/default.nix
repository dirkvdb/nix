{
  lib,
  config,
  pkgs,
  mkHome,
  llmAgentsPkgs,
  inputs,
  ...
}:
let
  inherit (config.local) user;
  cfg = config.local.apps.chatgpt;
  mkUserHome = mkHome user.name;
  solidcraftEnabled = config.local.apps.mcp.solidcraft.enable or false;
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  configureSolidcraft = pkgs.writeText "chatgpt-solidcraft-mcp.py" ''
    import os
    from pathlib import Path
    import tempfile
    import tomlkit

    config_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    config_home.mkdir(parents=True, exist_ok=True)
    path = config_home / "config.toml"
    original = path.read_text() if path.exists() else ""
    config = tomlkit.parse(original)
    servers = config.setdefault("mcp_servers", tomlkit.table())
    server = servers.setdefault("solidcraft", tomlkit.table())
    server.update({
        "command": "${pkgs.solidcraft}/bin/solidcraft-cli",
        "args": ["mcp"],
        "enabled": True,
        "tool_timeout_sec": 330,
    })
    updated = tomlkit.dumps(config)
    if updated != original:
        with tempfile.NamedTemporaryFile(mode="w", dir=config_home, delete=False) as tmp:
            tmp.write(updated)
            temporary = Path(tmp.name)
        try:
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)
  '';
in
{
  options.local.apps.chatgpt = {
    enable = lib.mkEnableOption "ChatGPT desktop application";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) (mkUserHome {
    home.packages = [ llmAgentsPkgs.chatgpt ];

    # ChatGPT and Codex share a writable config; preserve unrelated settings and comments.
    home.activation.chatgptSolidcraftMcp = lib.mkIf solidcraftEnabled (
      inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${python}/bin/python ${configureSolidcraft}
      ''
    );
  });
}
