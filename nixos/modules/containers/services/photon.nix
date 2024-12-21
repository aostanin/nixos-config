{
  lib,
  config,
  ...
}: let
  name = "photon";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/rtuszik/photon-docker:latest";
      volumes.data.destination = "/photon/photon_data";
      proxy.enable = true;
    };
  };
}
