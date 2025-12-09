{pkgs, ...}: {
  hardware.bluetooth.enable = true;

  services.home-assistant = {
    enable = true;
    # Starlink stats are broken in versions below 2025.6
    package = pkgs.unstable.home-assistant.overrideAttrs (oldAttrs: {
      # Fails under QEMU
      doInstallCheck = false;
    });
    config = {
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
          "100.64.0.0/10" # Tailscale
        ];
      };
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
      aiobmsble = pkgs.home-assistant.python.pkgs.buildPythonPackage rec {
        pname = "aiobmsble";
        version = "0.12.1";

        pyproject = true;

        nativeBuildInputs = with pkgs.home-assistant.python.pkgs; [
          setuptools-scm
        ];

        propagatedBuildInputs = with pkgs.home-assistant.python.pkgs; [
          bleak
          bleak-retry-connector
        ];

        src = pkgs.fetchFromGitHub {
          owner = "patman15";
          repo = pname;
          tag = version;
          hash = "sha256-EaIJPBWKI9KZl7wcK/piZjAcywbgkrztKO0xuXbhh7A=";
        };
      };

      bms_ble = pkgs.buildHomeAssistantComponent rec {
        owner = "patman15";
        domain = "bms_ble";
        version = "2.2.0";

        dependencies = [
          aiobmsble
        ];

        src = pkgs.fetchFromGitHub {
          owner = "patman15";
          repo = "BMS_BLE-HA";
          tag = version;
          hash = "sha256-qSff6sfDszdx56U0OdkCHWz4ndCGTTHS01lH8qwJYBI=";
        };
      };
      ef_ble = pkgs.buildHomeAssistantComponent rec {
        owner = "rabits";
        domain = "ef_ble";
        version = "0.5.5";

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
          hash = "sha256-474ov1RA7/D3tkvSjxvCeAxG26Gd72vgS87ao86b19s=";
        };

        postPatch = ''
          # 10 attempts often isn't enough when the Delta 3 Plus wakes from standby
          substituteInPlace custom_components/ef_ble/eflib/connection.py \
            --replace-fail "MAX_CONNECTION_ATTEMPTS = 10" "MAX_CONNECTION_ATTEMPTS = 100"
        '';
      };
    in [
      bms_ble
      ef_ble
    ];
    extraPackages = python3Packages: [
      python3Packages.starlink-grpc-core
      # FIXME: Why are these two needed? Should be propogated?
      python3Packages.grpcio
      python3Packages.crc
    ];
  };
}
