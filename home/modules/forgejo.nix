{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.forgejo;
  hosts = [
    "git.${secrets.domain}"
    "forgejo.${secrets.domain}"
  ];
in {
  options.localModules.forgejo = {
    enable = lib.mkEnableOption "forgejo-cli";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.unstable.forgejo-cli
      pkgs.unstable.tea
    ];

    sops.secrets."forgejo/token" = {};

    sops.templates."forgejo-cli-keys" = {
      mode = "0400";
      content = builtins.toJSON {
        hosts =
          lib.genAttrs
          hosts
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

    sops.templates."tea-config" = {
      mode = "0400";
      content = builtins.toJSON {
        logins =
          lib.imap0
          (i: host: {
            name = host;
            url = "https://${host}";
            token = config.sops.placeholder."forgejo/token";
            default = i == 0;
            user = secrets.forgejo.username;
          })
          hosts;
        preferences = {
          editor = false;
          flag_defaults.remote = "";
        };
      };
    };

    xdg.configFile."tea/config.yml".source =
      config.lib.file.mkOutOfStoreSymlink
      config.sops.templates."tea-config".path;
  };
}
