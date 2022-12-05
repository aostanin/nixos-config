{
  pkgs,
  config,
  lib,
  nixosConfig,
  ...
}: {
  home = {
    stateVersion = nixosConfig.system.stateVersion;

    file.".ssh/config".source = ../../secrets/ssh/ssh_config_root;

    file.".docker/config.json".source = ../../secrets/docker/config.json;
  };
}
