{
  pkgs,
  #inputs,
  config,
  userConfig,
  ...
}:
{
  imports = [
    (import ./core.nix { inherit pkgs config userConfig; })
    #./programs/k9s.nix
    #./programs/ghostty.nix
    #./programs/fish.nix
    #./programs/sketchybar.nix
  ];

  # sops.secrets = {
  #   # c... ssh
  #   "c/key".path = "${config.home.homeDirectory}/.ssh/id_c";
  #   "c/pub".path = "${config.home.homeDirectory}/.ssh/id_c.pub";
  #   "c/config".path = "${config.home.homeDirectory}/.config/git/include_c";

  #   # c... ssh
  #   "g/key".path = "${config.home.homeDirectory}/.ssh/id_g";
  #   "g/pub".path = "${config.home.homeDirectory}/.ssh/id_g.pub";
  #   "g/config".path = "${config.home.homeDirectory}/.config/git/include_g";

  #   "nuget".path = "${config.home.homeDirectory}/.config/nuget/nuget.config";
  # };

  home = {
    username = userConfig.username;
    homeDirectory = "/Users/${userConfig.username}";

    # Copy these dotfiles to the home directory as is
    file."${config.xdg.configHome}" = {
      source = ../dotfiles;
      recursive = true;
    };

    packages = with pkgs; [
      bitwarden-desktop
      alt-tab-macos
      iina
      karabiner-elements
      raycast
      wezterm
    ];
  };

  programs.zsh = {
    enable = true;
    initContent = ''
      # Ensure Nix paths come first
      export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"

      if [[ $(ps -o command= -p "$PPID" | awk '{print $1}') != 'fish' ]]
      then
          exec fish -l
      fi
    '';
  };

}
