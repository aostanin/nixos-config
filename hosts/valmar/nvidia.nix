{
  config,
  pkgs,
  ...
}: {
  services.xserver = {
    videoDrivers = ["nvidia"];
    screenSection = ''
      Option "nvidiaXineramaInfoOrder" "DFP-2"
      Option "metamodes" "HDMI-0: nvidia-auto-select +0+1440, DP-0: nvidia-auto-select +440+0"
    '';
  };
}
