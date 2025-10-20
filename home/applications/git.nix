{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {

    };

    settings = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;

      user = {
        name = "Dirk Vanden Boer";
        email = "dirk.vdb@gmail.com";
      };

      credential."https://github.com" = {
        helper = [
          "!gh auth git-credential"
        ];
      };
      credential."https://gist.github.com" = {
        helper = [
          "!gh auth git-credential"
        ];
      };
      credential."https://git.vito.be" = {
        interactive = false;
        modalPrompt = false;
        provider = "bitbucket";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      features = "side-by-side line-numbers decorations";
      syntax-theme = "Visual Studio Dark+";
    };
  };
}
