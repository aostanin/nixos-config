{
  pkgs,
  config,
  lib,
  ...
}: {
  localModules = {
    common.enable = true;

    desktop.enable = true;

    niri.extraDebug = ''
      render-drm-device "/dev/dri/by-path/pci-0000:00:02.0-render"
      ignore-drm-device "/dev/dri/by-path/pci-0000:01:00.0-card"
    '';

    gaming.enable = true;

    vdirsyncer.enable = true;
  };

  home.packages = with pkgs; [
    beets
  ];

  services.kanshi.settings = [
    {
      profile.name = "default";
      profile.outputs = [
        {
          criteria = "HDMI-A-1";
          status = "enable";
          scale = 1.0;
          mode = "1920x1080";
          position = "0,0";
        }
      ];
    }
  ];

  xdg.configFile."looking-glass/client.ini".text = lib.generators.toINI {} {
    app = {
      shmFile = "/dev/kvmfr0";
      renderer = "opengl";
    };
    input.escapeKey = "KEY_PAUSE";
    spice.port = 5910;
  };

  xdg.configFile."sunshine/sunshine.conf".text = ''
    # Why doesn't NvFBC work?
    encoder = nvenc
  '';
}
