{
  pkgs,
  config,
  lib,
  nixosConfig,
  ...
}:
with lib; {
  xdg.configFile."looking-glass/client.ini".text = generators.toINI {} {
    app = {
      shmFile = "/dev/kvmfr0";
      renderer = "opengl";
    };
    input.escapeKey = "KEY_PAUSE";
    spice.port = 5910;
  };
}
