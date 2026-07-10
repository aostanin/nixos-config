{
  lib,
  config,
  ...
}: let
  name = "forgejo";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    uid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.uid;
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = config.localModules.containers.gid;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "codeberg.org/forgejo/forgejo:15";
      raw.ports = ["2222:22"];
      raw.environment = let
        inherit (config.localModules.containers) domain;
      in rec {
        USER_UID = toString cfg.uid;
        USER_GID = toString cfg.gid;
        GITEA__SERVER__DOMAIN = "${name}.${domain}";
        GITEA__SERVER__SSH_DOMAIN = "git.${domain}";
        GITEA__SERVER__ROOT_URL = "https://${GITEA__SERVER__DOMAIN}/";
        # Default 3h fails CI kernel builds
        GITEA__ACTIONS__ENDLESS_TASK_TIMEOUT = "12h";
      };
      volumes.data = {
        destination = "/data";
        user = toString cfg.uid;
        group = toString cfg.gid;
      };
      healthcheck = {
        cmd = "wget --quiet --tries=1 --spider http://localhost:3000/api/healthz";
        startPeriod = "30s";
      };
      proxy = {
        enable = true;
        names = [name "git"];
        port = 3000;
      };
    };
  };
}
