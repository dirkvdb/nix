{
  pkgs,
  ...
}:
{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.caskaydia-mono
      nerd-fonts.roboto-mono
      fira-code
      monaspace
      cascadia-code
    ];
  };
}
