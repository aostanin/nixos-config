{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: let
  # TODO: Avoid having to import
  ssh_config = import ../../../secrets/ssh {
    pkgs = pkgs;
    secrets = secrets;
  };
in {
  programs.ssh = {
    enable = true;
    matchBlocks = ssh_config.matchBlocks;
  };
}
