{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.git;
in {
  options.localModules.git = {
    enable = lib.mkEnableOption "git";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      git-crypt
    ];

    programs.git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          name = secrets.user.fullName;
          email = secrets.user.emailAddress;
        };
        init = {
          defaultBranch = "main";
        };
        pull = {
          ff = "only";
        };
        push = {
          default = "current";
        };
        url = {
          "ssh://git@github.com/".insteadOf = "https://github.com/";
        };
        alias = {
          a = "add";
          br = "branch";
          c = "commit";
          cm = "commit -m";
          co = "checkout";
          cob = "checkout -b";
          d = "diff";
          f = "fetch";
          pl = "pull";
          po = "push origin";
          s = "status -s";
        };
      };
      ignores = [
        # Compiled source
        "*.com"
        "*.class"
        "*.dll"
        "*.exe"
        "*.o"
        "*.so"
        "*.pyc"

        # OS generated files
        ".DS_Store"
        "Thumbs.db"

        # Other SCM
        ".svn"

        # Junk files
        "*.bak"
        "*.swp"
        "*~"

        # IDE
        ".idea"
        "*.iml"
        ".vscode"

        # SyncThing
        ".stfolder"
        ".stignore"

        # Claude
        ".claude"

        # Nix
        "result"
      ];
    };
  };
}
