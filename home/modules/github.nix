{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.github;
in {
  options.localModules.github = {
    enable = lib.mkEnableOption "github-cli";
  };

  config = lib.mkIf cfg.enable {
    programs.gh = {
      enable = true;
      settings.aliases.co = "pr checkout";
    };

    programs.gh-dash = {
      enable = true;
      settings = {
        prSections = [
          {
            title = "mine";
            filters = "is:open author:@me";
          }
          {
            title = "review";
            filters = "is:open review-requested:@me";
          }
        ];
        issuesSections = [
          {
            title = "mine";
            filters = "is:open author:@me";
          }
          {
            title = "involved";
            filters = "is:open involves:@me -author:@me";
          }
        ];
      };
    };
  };
}
