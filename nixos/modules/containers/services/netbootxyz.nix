{
  lib,
  config,
  ...
}: let
  name = "netbootxyz";
  cfg = config.localModules.containers.services.${name};
  uid = toString config.localModules.containers.uid;
  gid = toString config.localModules.containers.gid;
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/linuxserver/netbootxyz:latest";
      raw.environment = {
        PUID = uid;
        PGID = gid;
      };
      raw.ports = ["69:69/udp"];
      volumes = {
        config = {
          destination = "/config";
          user = uid;
          group = gid;
        };
        assets = {
          destination = "/assets";
          user = uid;
          group = gid;
        };
      };
      proxy = {
        enable = true;
        port = 3000;
      };
    };
  };
}
