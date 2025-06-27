{pkgs, ...}: {
  hardware.bluetooth.enable = true;

  services.home-assistant = {
    enable = true;
    # Starlink stats are broken in versions below 2025.6
    package = pkgs.unstable.home-assistant;
    config = {
      bluetooth = {};
      config = {};
      history = {};
      image_upload = {};
      logbook = {};
      map = {};
      mobile_app = {};
      sun = {};

      frontend.themes = "!include_dir_merge_named themes";

      automation = "!include automations.yaml";
      script = "!include scripts.yaml";
      scene = "!include scenes.yaml";

      template = [
        {
          sensor = [
            {
              name = "Battery Bank";
              unit_of_measurement = "%";
              state = ''
                {% set battery1 = states('sensor.l_12100bnna60_b00077_battery') | float %}
                {% set battery2 = states('sensor.l_12100bnna60_b00067_battery') | float %}
                {{ ((battery1 + battery2) / 2) | round(1) }}
              '';
              availability = ''
                {{ is_number(states('sensor.l_12100bnna60_b00077_battery')) and
                   is_number(states('sensor.l_12100bnna60_b00067_battery')) }}
              '';
              device_class = "battery";
              state_class = "measurement";
            }
            {
              name = "Battery Bank Stored Energy";
              unit_of_measurement = "Wh";
              state = ''
                {% set energy1 = states('sensor.l_12100bnna60_b00077_stored_energy') | float %}
                {% set energy2 = states('sensor.l_12100bnna60_b00067_stored_energy') | float %}
                {{ (energy1 + energy2) | round(1) }}
              '';
              availability = ''
                {{ is_number(states('sensor.l_12100bnna60_b00077_stored_energy')) and
                   is_number(states('sensor.l_12100bnna60_b00067_stored_energy')) }}
              '';
              device_class = "energy_storage";
              state_class = "measurement";
            }
            {
              name = "Battery Bank Power";
              unit_of_measurement = "W";
              state = ''
                {% set power1 = states('sensor.l_12100bnna60_b00077_power') | float %}
                {% set power2 = states('sensor.l_12100bnna60_b00067_power') | float %}
                {{ (power1 + power2) | round(1) }}
              '';
              availability = ''
                {{ is_number(states('sensor.l_12100bnna60_b00077_power')) and
                   is_number(states('sensor.l_12100bnna60_b00067_power')) }}
              '';
              device_class = "power";
              state_class = "measurement";
            }
          ];
        }
      ];

      command_line = [
        {
          sensor = {
            name = "CPU Temperature";
            command = "cat /sys/class/thermal/thermal_zone0/temp";
            unit_of_measurement = "°C";
            value_template = "{{ value | multiply(0.001) | round(1) }}";
            scan_interval = 60;
            device_class = "temperature";
            state_class = "measurement";
          };
        }
        {
          sensor = {
            name = "NVMe Temperature";
            command = "cat /sys/class/nvme/nvme0/hwmon*/temp1_input";
            unit_of_measurement = "°C";
            value_template = "{{ value | multiply(0.001) | round(1) }}";
            scan_interval = 60;
            device_class = "temperature";
            state_class = "measurement";
          };
        }
      ];
    };
    extraComponents = [
      "backup"
      "default_config"
      "esphome"
      "starlink"
      "switchbot"
    ];
    customComponents = let
      bms_ble = pkgs.buildHomeAssistantComponent {
        owner = "patman15";
        domain = "bms_ble";
        version = "1.18.0-beta";

        src = pkgs.fetchFromGitHub {
          # TODO: Use upstream version when LiTime fix is merged
          owner = "aostanin";
          repo = "BMS_BLE-HA";
          rev = "e91bbf4944e53c4c44584e3612d9642cd0af32b9";
          hash = "sha256-AAwqpt0LTZzFpUfbqRpgwCHRiLqd3kwcQkq0L8Ww0R8=";
        };
      };
      ef_ble = pkgs.buildHomeAssistantComponent rec {
        owner = "rabits";
        domain = "ef_ble";
        version = "0.4.14";

        dependencies = with pkgs.home-assistant.python.pkgs; [
          ecdsa
          crc
          pycryptodome
          protobuf
        ];

        src = pkgs.fetchFromGitHub {
          inherit owner;
          repo = "ha-ef-ble";
          tag = "v${version}";
          hash = "sha256-PGHUNw3if50JrpjbXkBdpYw31fB0PdEKsaAchJJNqhI=";
        };
      };
    in [
      bms_ble
      ef_ble
    ];
    extraPackages = python3Packages: let
      yagrc = python3Packages.buildPythonPackage rec {
        pname = "yagrc";
        version = "1.1.2";

        pyproject = true;

        nativeBuildInputs = with python3Packages; [
          setuptools-scm
        ];

        propagatedBuildInputs = with python3Packages; [
          grpcio
          grpcio-reflection
          protobuf
        ];

        doCheck = false;

        src = pkgs.fetchFromGitHub {
          owner = "sparky8512";
          repo = pname;
          rev = "v${version}";
          hash = "sha256-nqUzDJfLsI8n8UjfCuOXRG6T8ibdN6fSGPPxm5RJhQk=";
        };
      };
      starlink-grpc = python3Packages.buildPythonPackage rec {
        pname = "starlink-grpc";
        version = "1.2.3";

        pyproject = true;

        nativeBuildInputs = with python3Packages; [
          setuptools-scm
        ];

        propagatedBuildInputs = with python3Packages; [
          grpcio
          protobuf
          typing-extensions
          yagrc
        ];

        postPatch = ''
          cd packaging
        '';

        src = pkgs.fetchFromGitHub {
          owner = "sparky8512";
          repo = "starlink-grpc-tools";
          rev = "v${version}";
          hash = "sha256-TXj8cU5abVIA81vEylYgZCIAUk31BppwRdHMl9kOEPQ=";
        };
      };
    in [
      starlink-grpc
      python3Packages.grpcio
    ];
  };
}
