{
  pkgs,
  config,
  lib,
  ...
}: {
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
    capture = x11
    encoder = nvenc
  '';
}
