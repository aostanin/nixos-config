{ pkgs, config, lib, ... }:

{
  home.file = {
    ".ssh/config".source = ./ssh_config;
  };
}
