{
  pkgs,
  config,
  lib,
  osConfig,
  secrets,
  ...
}: {
  home = {
    stateVersion = osConfig.system.stateVersion;

    # TODO: Nix-ify SSH config
    file.".ssh/config".source = ../../secrets/ssh/ssh_config_root;

    file.".docker/config.json".source = secrets.docker."config.json";
  };
}
