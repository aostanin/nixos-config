{
  pkgs,
  config,
  lib,
  ...
}: {
  localModules = {
    common = {
      enable = true;
      enableNvidia = true;
    };

    desktop.enable = true;

    gaming.enable = true;

    # VFIO passthrough can't take the card while niri holds it.
    niri.extraDebug = ''
      ignore-drm-device "/dev/dri/by-path/pci-0000:01:00.0-render"
    '';
  };
}
