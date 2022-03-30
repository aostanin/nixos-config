{ pkgs, config, lib, ... }:

{
  home.file = {
    # TODO: nixify ssh config
    ".ssh/config".source = ../../../secrets/ssh/ssh_config;
  };
}
