{...}: {
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
}
