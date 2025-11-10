{ lib, config, ... }:
let
  inherit (config.local) user;
in
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
  home-manager.users.${user.name} = {
    xdg.dataFile = lib.mkMerge [
      {
        "icons/hicolor/256x256/apps/chatgpt.png".source = ./icons/ChatGPT.png;
        "icons/hicolor/256x256/apps/youtube.png".source = ./icons/youtube.png;
        "icons/hicolor/256x256/apps/gmail.png".source = ./icons/gmail.png;
        "icons/hicolor/256x256/apps/outlook.png".source = ./icons/outlook.png;
      }

      (mkWebApp {
        name = "ChatGPT";
        url = "https://chatgpt.com/";
        comment = "ChatGPT Web Application";
        icon = "chatgpt";
      })

      (mkWebApp {
        name = "YouTube";
        url = "https://youtube.com/";
        icon = "youtube";
      })

      (mkWebApp {
        name = "Gmail";
        url = "https://mail.google.com/";
        icon = "gmail";
      })

      (mkWebApp {
        name = "Outlook";
        url = "https://outlook.office365.com/";
        icon = "outlook";
      })
    ];
  };
}
