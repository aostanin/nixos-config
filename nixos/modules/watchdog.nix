{
  lib,
  config,
  ...
}: let
  cfg = config.localModules.watchdog;
in {
  options.localModules.watchdog = {
    enable = lib.mkEnableOption "iTCO hardware watchdog and panic-reboot recovery for a headless host";
  };

  config = lib.mkIf cfg.enable {
    # Drop the AMT watchdog driver so the iTCO chipset watchdog is the only one
    # and is always watchdog0; otherwise the two race and systemd can grab the
    # inert iamt_wdt instead. AMT serial-over-LAN is unaffected.
    boot.blacklistedKernelModules = ["mei_wdt"];

    boot.kernel.sysctl = {
      "kernel.panic" = 10; # reboot 10s after a panic instead of hanging
      "kernel.panic_on_oops" = 1; # treat an oops as a panic on this headless host
    };

    # Arm the iTCO hardware watchdog: chipset resets the host if systemd stops
    # petting /dev/watchdog (catches silent lockups the panic reboot can't).
    systemd.settings.Manager = {
      RuntimeWatchdogSec = "30s";
      RebootWatchdogSec = "2min";
    };
  };
}
