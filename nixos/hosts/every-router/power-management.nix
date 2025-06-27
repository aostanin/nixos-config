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

  # Set up fan
  boot.initrd.preDeviceCommands = ''
    echo 50000 > /sys/class/thermal/thermal_zone0/trip_point_2_temp
    echo 40000 > /sys/class/thermal/thermal_zone0/trip_point_3_temp
    echo 30000 > /sys/class/thermal/thermal_zone0/trip_point_4_temp
  '';

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
        };
      '';
    }
  ];
}
