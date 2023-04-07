{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.localModules.pikvm;
  secrets = import ../../secrets;
in {
  options.localModules.pikvm = {
    enable = mkEnableOption "pikvm";
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [
      "video=HDMI-A-1:1280x1024@60e"
    ];

    # For PiKVM console
    systemd.services."serial-getty@ttyACM0" = {
      enable = true;
      serviceConfig = {
        Environment = "TERM=xterm-256color";
      };
    };

    services.udev.extraRules = ''
      # PiKVM Serial
      SUBSYSTEMS=="usb", KERNEL=="ttyACM*", ATTRS{idVendor}=="1d6b", ATTRS{idProduct}=="0104", TAG+="systemd", ENV{SYSTEMD_WANTS}+="serial-getty@%k.service"
    '';
  };
}
