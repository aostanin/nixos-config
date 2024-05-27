{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ../../modules
  ];

  localModules = {
    common.enable = true;

    desktop.enable = true;

    sway = {
      primaryOutput = "HDMI-A-1";
      output = {
        "*" = {
          disable = "";
        };
        # "DP-1" = {
        #   enable = "";
        #   mode = "3440x1440";
        #   position = "0 0";
        # };
        "HDMI-A-1" = {
          enable = "";
          mode = "1920x1080";
          position = "0 0";
        };
      };
    };

    gaming.enable = true;
  };

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
