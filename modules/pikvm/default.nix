{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.hardware.pikvm;
  secrets = import ../../secrets;
in {
  options.hardware.pikvm = {
    enable = mkEnableOption "pikvm";
  };

  config = mkIf cfg.enable {
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
