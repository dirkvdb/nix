{ pkgs, ... }:
{
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "nl_BE.UTF-8/UTF-8"
      "nl_NL.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      LC_ADDRESS = "nl_BE.UTF-8";
      LC_IDENTIFICATION = "nl_BE.UTF-8";
      LC_MEASUREMENT = "nl_BE.UTF-8";
      LC_MONETARY = "nl_BE.UTF-8";
      LC_NAME = "nl_BE.UTF-8";
      LC_NUMERIC = "nl_BE.UTF-8";
      LC_PAPER = "nl_BE.UTF-8";
      LC_TELEPHONE = "nl_BE.UTF-8";
      LC_TIME = "nl_BE.UTF-8";
    };
  };

  # Use terminus-nerdfont for the virtual console so that powerline
  # separator glyphs render correctly in TTY sessions (Ctrl+Alt+Fx).
  # Note: Nerd Font icons in the Supplementary PUA (U+F0000+) cannot
  # be displayed in the TTY regardless of font choice.
  console = {
    packages = [ pkgs.powerline-fonts ];
    font = "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v32n.psf.gz";
    earlySetup = true;
  };
}
