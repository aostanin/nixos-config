{ pkgs, config, lib, ... }:
let
  ssh_config = import ../../../secrets/ssh;
in
{
  programs.ssh = {
    enable = true;
    matchBlocks = ssh_config.matchBlocks;
  };
}
