{ config, lib, ... }:
let
  mkWebApp =
    {
      name,
      url,
      comment ? "",
      icon ? null,
    }:
    let
      desktopName = lib.toLower name;
      iconPath = if icon != null then icon else desktopName;
    in
    {
      "applications/${desktopName}.desktop" = {
        text = ''
          [Desktop Entry]
          Version=1.0
          Name=${name}
          Comment=${comment}
          Exec=nixcfg-launch-webapp "${url}"
          Terminal=false
          Type=Application
          Icon=${iconPath}
          StartupNotify=true
        '';
      };
    };
in
{
  xdg.dataFile = lib.mkMerge [
    { "xdg-desktop-portal/icons".source = ./webapps/icons; }

    (mkWebApp {
      name = "ChatGPT";
      url = "https://chatgpt.com/";
      comment = "ChatGPT Web Application";
      icon = "${config.xdg.dataHome}/xdg-desktop-portal/icons/ChatGPT.png";
    })

    (mkWebApp {
      name = "YouTube";
      url = "https://youtube.com/";
      icon = "youtube";
    })
  ];
}
