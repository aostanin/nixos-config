{
  lib,
  config,
  ...
}: let
  name = "forgejo";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "codeberg.org/forgejo/forgejo:8";
      raw.ports = ["2222:22"];
      raw.environment = let
        inherit (config.localModules.containers) domain;
      in rec {
        USER_UID = uid;
        USER_GID = gid;
        GITEA__SERVER__DOMAIN = "${name}.${domain}";
        GITEA__SERVER__SSH_DOMAIN = "git.${domain}";
        GITEA__SERVER__ROOT_URL = "https://${GITEA__SERVER__DOMAIN}/";
      };
      volumes.data = {
        destination = "/data";
        user = uid;
        group = gid;
      };
      proxy = {
        enable = true;
        names = [name "git"];
        port = 3000;
      };
    };
  };
}
