{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.gaming;
in {
  options.localModules.gaming = {
    enable = lib.mkEnableOption "gaming";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # Tools
      bottles
      gamescope
      mangohud
      pegasus-frontend

      # Emulators
      cemu
      dolphin-emu
      retroarch # TODO: Add cores?
      rpcs3
      ryujinx
      nur.repos.aprilthepink.suyu-mainline
    ];
  };
}
