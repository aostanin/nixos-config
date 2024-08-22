{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.pikvm;
in {
  options.localModules.pikvm = {
    enable = lib.mkEnableOption "pikvm";

    enableUsbSerial = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Enable getty on USB serial.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams = [
      "video=HDMI-A-1:1280x1024@60e"
    ];

    # For PiKVM console
    systemd.services."serial-getty@ttyACM0" = lib.mkIf cfg.enableUsbSerial {
      enable = true;
      serviceConfig = {
        Environment = "TERM=xterm-256color";
      };
    };

    services.udev.extraRules = lib.mkIf cfg.enableUsbSerial ''
      # PiKVM Serial
      SUBSYSTEMS=="usb", KERNEL=="ttyACM*", ATTRS{idVendor}=="1d6b", ATTRS{idProduct}=="0104", TAG+="systemd", ENV{SYSTEMD_WANTS}+="serial-getty@%k.service"
    '';
  };
}
