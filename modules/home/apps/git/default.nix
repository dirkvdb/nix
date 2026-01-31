{
  config,
  mkHome,
  ...
}:
let
  inherit (config.local) user;
  mkUserHome = mkHome user.name;
in
{
  config = mkUserHome {
    programs.git = {
      enable = true;
      lfs.enable = true;

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
  };
}
