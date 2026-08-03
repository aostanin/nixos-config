{
  lib,
  pkgs,
  ...
}: let
  # cooling-levels descend (active-low header), so its last entry is full speed
  # and 255 is off. pwm-fan probes to 255 while initialising its cooling state
  # to max, and set_cur_state() no-ops on an unchanged target, so after a warm
  # boot (SoC already past the top trip) the fan never starts. Writing the
  # full-speed level also resets that state, since update_state() buckets it
  # back to 0.
  fanWatchdog = pkgs.writeShellScript "fan-watchdog" ''
    set -u
    PATH=${lib.makeBinPath [pkgs.coreutils]}

    zone=/sys/class/thermal/thermal_zone0

    fan=""
    for h in /sys/class/hwmon/hwmon*; do
      [ "$(cat "$h/name" 2>/dev/null)" = pwmfan ] || continue
      fan="$h"
      break
    done
    [ -n "$fan" ] || exit 0

    raw="$(od -An -tu4 --endian=big /proc/device-tree/pwm-fan/cooling-levels 2>/dev/null)" || exit 0
    levels=($raw)
    [ ''${#levels[@]} -gt 0 ] || exit 0
    full=''${levels[-1]}

    top=0
    for t in "$zone"/trip_point_*_type; do
      [ "$(cat "$t" 2>/dev/null)" = active ] || continue
      v="$(cat "''${t%_type}_temp" 2>/dev/null)" || continue
      [ "$v" -gt "$top" ] && top="$v"
    done
    [ "$top" -gt 0 ] || exit 0

    temp="$(cat "$zone/temp" 2>/dev/null)" || exit 0
    pwm="$(cat "$fan/pwm1" 2>/dev/null)" || exit 0

    [ "$temp" -gt "$top" ] && [ "$pwm" -ne "$full" ] || exit 0

    echo "fan-watchdog: pwm $pwm at $((temp / 1000))C, past the $((top / 1000))C trip; forcing $full" >&2
    echo "$full" > "$fan/pwm1"
  '';
in {
  boot.kernelParams = [
    "pcie_aspm.policy=default" # powersave causes instability
    "nmi_watchdog=0" # Match PowerTOP
  ];

  # Match PowerTOP
  services.udev.extraRules = ''
    SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  '';

  boot.kernel.sysctl = {
    # Match PowerTOP
    "vm.dirty_writeback_centisecs" = 1500;
  };

  # Increase mid fan speed and lower the cpu-thermal trip points so the
  # pwm-fan kicks in earlier than the DTS defaults (60/85/115 °C).
  hardware.deviceTree.overlays = [
    {
      name = "bpi-r3-mini-fan-pwm";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
            compatible = "bananapi,bpi-r3mini";

            fragment@0 {
                target-path = "/pwm-fan";
                __overlay__ {
                    cooling-levels = <255 40 0>;
                };
            };

            fragment@1 {
                target-path = "/thermal-zones/cpu-thermal/trips/active-high";
                __overlay__ {
                    temperature = <50000>;
                };
            };

            fragment@2 {
                target-path = "/thermal-zones/cpu-thermal/trips/active-med";
                __overlay__ {
                    temperature = <40000>;
                };
            };

            fragment@3 {
                target-path = "/thermal-zones/cpu-thermal/trips/active-low";
                __overlay__ {
                    temperature = <30000>;
                };
            };
        };
      '';
    }
  ];

  systemd.services.fan-watchdog = {
    description = "Recover the pwm-fan when the driver latches it off";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = fanWatchdog;
    };
  };
  systemd.timers.fan-watchdog = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
    };
  };
}
