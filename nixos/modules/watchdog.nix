{
  lib,
  config,
  ...
}: let
  cfg = config.localModules.watchdog;
in {
  options.localModules.watchdog = {
    enable = lib.mkEnableOption "hardware watchdog and panic-reboot recovery for a headless host";
  };

  config = lib.mkIf cfg.enable {
    # Drop the AMT watchdog driver so the iTCO chipset watchdog is the only one
    # and is always watchdog0; otherwise the two race and systemd can grab the
    # inert iamt_wdt instead. AMT serial-over-LAN is unaffected.
    boot.blacklistedKernelModules = ["mei_wdt"];

    # A CPU that locks up with interrupts off writes nothing at all unless the
    # NMI detector is running, so a silent freeze leaves no trace to diagnose.
    # mkAfter so consoleblank=0 lands after common.nix's consoleblank=300
    boot.kernelParams = lib.mkAfter [
      "nmi_watchdog=1"
      "consoleblank=0" # A blanked console hides the panic from an attached KVM
    ];

    boot.kernel.sysctl = {
      "kernel.panic" = 10; # reboot 10s after a panic instead of hanging
      "kernel.panic_on_oops" = 1; # treat an oops as a panic on this headless host
      "kernel.hardlockup_panic" = 1;
      # Soft lockups (20s) and RCU stalls (21s) only warn, and a frozen host
      # never gets that warning to disk; as panics they reach EFI pstore before
      # the 30s watchdog reset. hung_task_panic stays off: ZFS can trip it.
      "kernel.softlockup_panic" = 1;
      "kernel.panic_on_rcu_stall" = 1;
    };

    # Arm the hardware watchdog (iTCO on Intel, sp5100_tco on AMD): it resets the host if systemd stops
    # petting /dev/watchdog (catches silent lockups the panic reboot can't).
    systemd.settings.Manager = {
      RuntimeWatchdogSec = "30s";
      RebootWatchdogSec = "2min";
    };
  };
}
