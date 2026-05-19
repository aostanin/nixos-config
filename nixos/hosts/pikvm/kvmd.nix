{
  pkgs,
  lib,
  config,
  ...
}: {
  boot.kernelModules = ["dln2" "gpio-dln2"];

  # From https://github.com/zappanaut/dln2-dkms/tree/main/udev
  services.udev.extraRules = lib.mkAfter ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="6170", RUN+="${pkgs.kmod}/bin/modprobe -b dln2"
    ACTION=="add", SUBSYSTEM=="drivers", ENV{DEVPATH}=="/bus/usb/drivers/dln2", ATTR{new_id}="1d50 6170 ff"
    KERNEL=="gpiochip*", SUBSYSTEM=="gpio", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6170", OWNER="root", GROUP="gpio", MODE="0660", SYMLINK+="gpio-by-serial/$attr{serial}"
  '';

  systemd.tmpfiles.rules = ["d /dev/gpio-by-serial 0755 root root -"];

  sops.secrets."pikvm/htpasswd".owner = "kvmd";

  services.kvmd = {
    enable = true;
    janus.enable = true;

    htpasswdFile = config.sops.secrets."pikvm/htpasswd".path;

    overrideConfig = let
      hkLed = pin: {
        driver = "hk";
        inherit pin;
        mode = "input";
      };
      hkButton = pin: {
        driver = "hk";
        inherit pin;
        mode = "output";
        switch = false;
      };
      atxButton = pin: pulse: {
        driver = "atx_port1";
        inherit pin pulse;
        mode = "output";
        switch = false;
      };
      atxLed = pin: {
        driver = "atx_port1";
        inherit pin;
        mode = "input";
      };
      gpioScheme =
        builtins.listToAttrs (lib.concatMap (n: [
            {
              name = "ch${toString n}_led";
              value = hkLed n;
            }
            {
              name = "ch${toString n}_button";
              value = hkButton n;
            }
          ])
          (lib.range 0 3))
        // {
          atx1_reset_button = atxButton 7 {
            delay = 0.5;
            max_delay = 1.0;
          };
          atx1_power_button = atxButton 8 {
            delay = 0.5;
            max_delay = 1.0;
          };
          atx1_power_button_long = atxButton 8 {
            delay = 5.5;
            min_delay = 5.0;
            max_delay = 6.0;
          };
          atx1_power_led = atxLed 14;
          atx1_hdd_led = atxLed 15;
        };
    in {
      otg.devices.serial.enabled = true;
      kvmd = {
        atx.type = "disabled";
        gpio = {
          drivers = {
            hk = {
              type = "xh_hk4401";
              device = "/dev/ttyUSB0";
            };
            atx_port1 = {
              type = "gpio";
              device = "/dev/gpio-by-serial/E6613872CFA2662F";
            };
          };
          scheme = gpioScheme;
          view = {
            header.title = ''<img class="led-gray" src="/share/svg/kvm.svg" title=""><span>KVM & ATX</span>'';
            table = [
              ["#" ''#<div class="pos-rel"><span class="pos-abs-middle">KVM-Switch</span></div>'' ''#<span class="padding-x-1">NAME</span>'' "#PWR" "#HDD" "#&nbsp;" ''#<div class="pos-rel"><span class="pos-abs-middle">ATX Power and Reset</span></div>'']
              ["ch0_led|red" "ch0_button||Port 1" ''#<span class="x-name">elena</span>'' "atx1_power_led|green" "atx1_hdd_led|yellow" "#" "atx1_power_button|confirm|Power" "atx1_power_button_long|confirm|Power" "atx1_reset_button|confirm|Reset"]
              ["ch1_led|red" "ch1_button||Port 2" ''#<span class="x-name">vfio</span>'']
              ["ch2_led|red" "ch2_button||Port 3"]
              ["ch3_led|red" "ch3_button||Port 4"]
            ];
          };
        };
      };
    };
    webCss = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/zappanaut/pikvm-usb-atx-ctrl/main/kvmd/web.css";
      hash = "sha256-p/z/x59aPTZZEHPs6lRf/S6ywLdE/VOI3D7erKbsz5Y=";
    };

    # 1280x1024 preferred for BIOS compatibility
    edidHex = pkgs.writeText "pikvm-edid.hex" ''
      00FFFFFFFFFFFF005262888800888888
      1C150103800000780AEE91A3544C9926
      0F505425400001000100010001000100
      010001010101D51B0050500019400820
      B80080001000001EEC2C80A070381A40
      3020350040442100001E000000FC0050
      492D4B564D20566964656F0A000000FD
      00323D0F2E0F0000000000000000014D
      02030400DE0D20A03058122030203400
      F0B400000018E01500A0400016303020
      3400000000000018B41400A050D01120
      3020350080D810000018AB22A0A05084
      1A3030203600B00E1100001800000000
      00000000000000000000000000000000
      00000000000000000000000000000000
      00000000000000000000000000000045
    '';
  };
}
