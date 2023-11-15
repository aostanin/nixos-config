{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: {
  home.packages = with pkgs; [
    git-crypt
  ];

  programs.git = {
    enable = true;
    userName = secrets.user.fullName;
    userEmail = secrets.user.emailAddress;
    extraConfig = {
      init = {
        defaultBranch = "master";
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
    };
    aliases = {
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
    ];
  };
}
