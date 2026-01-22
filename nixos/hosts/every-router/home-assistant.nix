{pkgs, ...}: let
  aiobmsble = python3Packages:
    python3Packages.buildPythonPackage rec {
      pname = "aiobmsble";
      version = "0.12.1";

      pyproject = true;

      nativeBuildInputs = with python3Packages; [
        setuptools-scm
      ];

      propagatedBuildInputs = with python3Packages; [
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
  victron-ble = python3Packages:
    python3Packages.buildPythonPackage rec {
      pname = "victron-ble";
      version = "0.9.3";

      pyproject = true;

      nativeBuildInputs = with python3Packages; [
        setuptools-scm
      ];

      dependencies = with python3Packages; [
        bleak
        click
        pycryptodome
      ];

      src = pkgs.fetchFromGitHub {
        owner = "keshavdv";
        repo = pname;
        # To fix https://github.com/keshavdv/victron-ble/issues/20
        rev = "c721522bee77fdf3b2cf304d5b9afc46e39bffe4";
        hash = "sha256-IV3W71N8c5ESY3XdpOeITOQ+a3jk36/3ZbIcU5rq788=";
      };

      # VERSION file in repo not updated
      postPatch = ''
        echo "${version}" >victron_ble/VERSION
      '';
    };
in {
  hardware.bluetooth.enable = true;

  services.home-assistant = {
    enable = true;
    # TODO: Downgrade to stable
    package = pkgs.unstable.home-assistant;
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
      energy = {};
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
        {
          sensor = {
            name = "Modem Signal Quality";
            command = "${pkgs.modemmanager}/bin/mmcli -m 0 -J | ${pkgs.jq}/bin/jq -r '.modem.generic.\"signal-quality\".value'";
            unit_of_measurement = "%";
            scan_interval = 60;
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
      bms_ble = pkgs.buildHomeAssistantComponent rec {
        owner = "patman15";
        domain = "bms_ble";
        version = "2.2.0";

        dependencies = [
          (aiobmsble pkgs.home-assistant.python.pkgs)
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
      victron_hacs = pkgs.buildHomeAssistantComponent rec {
        owner = "keshavdv";
        domain = "victron_ble";
        version = "0.1.2";

        dependencies = with pkgs.home-assistant.python.pkgs; [
          (victron-ble pkgs.home-assistant.python.pkgs)
          bluetooth-sensor-state-data
        ];

        src = pkgs.fetchFromGitHub {
          owner = "keshavdv";
          repo = "victron-hacs";
          rev = "4bd629e7abe412df8ad495e5421af4fae97e2b15";
          hash = "sha256-GgNnDWlVYnFhiiCCWYsS4uuOxjdCZtgeKVpGJ0TkxqE=";
        };
      };
    in [
      bms_ble
      ef_ble
      victron_hacs
    ];

    extraPackages = python3Packages:
      with python3Packages; [
        (victron-ble python3Packages)
        bluetooth-sensor-state-data
        # FIXME: Why are these needed? Should be propogated?
        starlink-grpc-core
        grpcio
        crc
        ecdsa
        (aiobmsble python3Packages)
      ];
  };
}
