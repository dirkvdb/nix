{
  config,
  inputs,
  lib,
  mkHome,
  pkgs,
  ...
}:
let
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
  stateDir = "${user.homeDir}/.local/state/flea";
  jsonFormat = pkgs.formats.json { };
  settingsFile = jsonFormat.generate "flea-ui-settings.json" {
    view = "list";
    pickerView = "list";
    density = "tight";
    columns = [
      "name"
      "size"
      "date"
    ];
    columnsLimit = 3;
    columnWidths = { };
    addressBar = "breadcrumb";
    sort = {
      key = "name";
      reverse = false;
    };
    rememberSort = true;
    folderSorts."${user.homeDir}/nix" = {
      key = "name";
      reverse = true;
    };
    rememberViewPerFolder = false;
    folderViews = { };
    dual = {
      paths = [
        user.homeDir
        "~/dev"
      ];
      focus = 0;
      split = 5000;
    };
    foldersFirst = true;
    groupByKind = false;
    hidden = false;
    langMarks = true;
    hiddenLast = false;
    showGitStatus = true;
    highlightToday = false;
    wrapAtEnds = false;
    escapeUp = false;
    openMode = "double";
    clickRename = true;
    openFoldersWhileDragging = false;
    keyHints = false;
    startIn = "home";
    startFolder = "";
    lastPath = user.homeDir;
    lastTabs = {
      paths = [ user.homeDir ];
      index = 0;
    };
    newTab = "current";
    trashAutoEmpty = false;
    trashSweptOn = 0;
    places = {
      favourites = [
        {
          path = "${user.homeDir}/dev";
          label = "dev";
        }
      ];
      showHome = true;
      showRecent = false;
      showNetwork = true;
      showDevices = false;
      showTrash = true;
      driveSize = false;
      trashCount = false;
      showUnmounted = true;
      showTags = false;
      rail = "shown";
      autoHide = false;
      sidebarWidth = 224;
    };
    shelf = {
      enabled = false;
      bar = true;
      rail = "off";
      screenshots = true;
      recordings = true;
      recent = 3;
    };
    preview = {
      column = true;
      loadOn = "automatic";
      thumbnails = "media";
      thumbSize = "xlarge";
      thumbNetwork = true;
      thumbPhone = false;
      thumbUsb = true;
      ctrlZoom = true;
      volume = 100;
      width = 0;
      tracks = [ ];
      wrap = false;
    };
    previewFacts = "compact";
    keys = "default";
    display = {
      textSize.mode = 14;
      hyprlandIcons = true;
    };
    menu.hidden = [
      "delete"
      "openTerminal"
      "placeMenu"
      "runScript"
      "moveto"
      "copyto"
      "properties"
      "permissions"
      "copyAs"
      "pasteAs"
      "invertSelection"
      "extThumbs"
      "run"
      "openAsText"
      "openAgent"
    ];
    updates.autoCheck = false;
    plugins."flea.dropbox".enabled = false;
  };
in
{
  config = lib.mkIf (pkgs.stdenv.isLinux && (config.local.desktop.enable or false)) (mkUserHome {
    # Flea writes its UI state here; copy instead of linking the generated settings from the store.
    home.activation.fleaSettings = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg stateDir}
      run ${pkgs.coreutils}/bin/cp --remove-destination --no-preserve=mode ${settingsFile} ${lib.escapeShellArg "${stateDir}/ui.json"}
      run ${pkgs.coreutils}/bin/chmod 600 ${lib.escapeShellArg "${stateDir}/ui.json"}
    '';
  });
}
