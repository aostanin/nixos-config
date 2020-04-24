{ pkgs, config, lib, ... }:

{
  programs.gpg.enable = true;

  services.gpg-agent.enable = true;
}
