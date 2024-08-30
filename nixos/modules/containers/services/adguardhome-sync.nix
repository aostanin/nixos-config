{
  lib,
  config,
  ...
}: let
  name = "adguardhome-sync";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/linuxserver/adguardhome-sync:latest";
      raw.environment = {
        PUID = uid;
        PGID = gid;
      };
      # TODO: Automatically set up master/replicants?
      volumes.config = {
        destination = "/config";
        user = uid;
        group = gid;
      };
      proxy = {
        enable = true;
        port = 8080;
      };
    };
  };
}
