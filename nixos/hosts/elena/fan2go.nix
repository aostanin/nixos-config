{
  lib,
  pkgs,
  ...
}: let
  drives = import ./drives.nix;

  # 1% = minPwm, 100% = maxPwm.
  driveSteps = {
    "35" = "1%";
    "40" = "30%";
    "45" = "70%";
    "48" = "100%";
  };

  config = (pkgs.formats.yaml {}).generate "fan2go.yaml" {
    dbPath = "/var/lib/fan2go/fan2go.db";
    # Each drivetemp read is an ATA command to the drive.
    tempSensorPollingRate = "2s";

    sensors =
      [
        {
          id = "cpu";
          hwmon = {
            platform = "k10temp";
            index = 1;
          };
        }
      ]
      ++ map (device: {
        id = device;
        disk = {inherit device;};
      })
      drives;

    curves =
      [
        {
          id = "cpu";
          linear = {
            sensor = "cpu";
            steps = {
              "60" = "1%";
              "75" = "40%";
              "90" = "100%";
            };
          };
        }
        {
          id = "case";
          function = {
            type = "maximum";
            curves = ["cpu"] ++ drives;
          };
        }
      ]
      ++ map (device: {
        id = device;
        linear = {
          sensor = device;
          steps = driveSteps;
        };
      })
      drives;

    fans = [
      {
        # CHA_FAN1, which carries every case fan through a hub.
        id = "case";
        hwmon = {
          platform = "nct6799";
          rpmChannel = 4;
          pwmChannel = 4;
        };
        curve = "case";
        neverStop = true;
        # ASRock FanTuning measured the stall point at 23% (59).
        minPwm = 70;
        maxPwm = 255;
      }
    ];
  };

  # Hands CHA_FAN1 back to the BIOS curve (SmartFan IV). fan2go's own restore
  # skips crashes, and it writes any controlMode integer above 2 as 0 (full speed).
  restoreBiosCurve = pkgs.writeShellScript "fan2go-restore-bios-curve" ''
    for d in /sys/class/hwmon/hwmon*; do
      read -r name < "$d/name"
      if [ "$name" = nct6799 ]; then echo 5 > "$d/pwm4_enable"; fi
    done
  '';
in {
  boot.kernelModules = ["drivetemp"];

  environment.systemPackages = [pkgs.fan2go];

  systemd.services.fan2go = {
    description = "fan2go case fan control";
    wantedBy = ["multi-user.target"];
    after = ["systemd-modules-load.service"];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.fan2go} -c ${config} --no-style";
      ExecStopPost = restoreBiosCurve;
      StateDirectory = "fan2go";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
