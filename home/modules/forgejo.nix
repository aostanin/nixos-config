{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.forgejo;
in {
  options.localModules.forgejo = {
    enable = lib.mkEnableOption "forgejo-cli";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.unstable.forgejo-cli
    ];

    sops.secrets."forgejo/token" = {};

    sops.templates."forgejo-cli-keys" = {
      mode = "0400";
      content = builtins.toJSON {
        hosts =
          lib.genAttrs
          [
            "git.${secrets.domain}"
            "forgejo.${secrets.domain}"
          ]
          (_: {
            type = "Application";
            name = secrets.forgejo.username;
            token = config.sops.placeholder."forgejo/token";
          });
        aliases = {};
        default_ssh = [];
      };
    };

    xdg.dataFile."forgejo-cli/keys.json".source =
      config.lib.file.mkOutOfStoreSymlink
      config.sops.templates."forgejo-cli-keys".path;
  };
}
