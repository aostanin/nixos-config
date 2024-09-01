{
  pkgs,
  config,
  lib,
  ...
}: {
  localModules.common.enable = true;

  # Deploying from Linux to Darwin is currently broken in nixvim.
  # ref: https://github.com/nix-community/nixvim/issues/1644#issuecomment-2211376718
  # TODO: Enable once 24.11 is released
  localModules.neovim.enable = false;
}
