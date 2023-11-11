{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}: {
  home = {
    stateVersion = osConfig.system.stateVersion;

    file.".ssh/config".source = ../../secrets/ssh/ssh_config_root;

    file.".docker/config.json".source = ../../secrets/docker/config.json;
  };
}
