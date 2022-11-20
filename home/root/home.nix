{
  pkgs,
  config,
  lib,
  ...
}: {
  home.file.".ssh/config".source = ../../secrets/ssh/ssh_config_root;
}
