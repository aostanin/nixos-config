{
  config,
  pkgs,
  ...
}: let
  serial = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";
  ender3v2KlipperConfigs = pkgs.fetchFromGitHub {
    owner = "LeeOtts";
    repo = "Ender3v2-Klipper-Configs";
    rev = "3b9a885bc06a73c6d34f8095e80e32dfc62ee141";
    hash = "sha256-EQtQZKpzDgiDjL0WBv+Ysrd/aVMuVmsEXEut4etqbKU=";
  };
in {
  systemd.tmpfiles.rules =
    map
    (f: "L+ ${config.services.klipper.configDir}/${f} - - - - ${ender3v2KlipperConfigs}/${f}") [
      "macros.cfg"
      "Adaptive_Meshing.cfg"
      "Line_Purge.cfg"
    ];

  # Restart Klipper when the printer is powered on
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", ACTION=="add", RUN+="/bin/sh -c 'echo RESTART > ${config.services.klipper.inputTTY}'"
  '';

  services.klipper = {
    enable = true;
    user = "moonraker";
    group = "moonraker";
    settings = {
      "include macros.cfg" = {};
      "include Adaptive_Meshing.cfg" = {};
      "include Line_Purge.cfg" = {};
      virtual_sdcard.path = "${config.services.moonraker.stateDir}/gcodes";
      display_status = {};
      exclude_object = {};
      respond.default_prefix = "";
      mcu = {
        inherit serial;
        restart_method = "command";
      };
      "temperature_sensor raspberry_pi" = {
        sensor_type = "temperature_host";
        min_temp = 10;
        max_temp = 100;
      };
      "temperature_sensor mcu_temp" = {
        sensor_type = "temperature_mcu";
        min_temp = 0;
        max_temp = 100;
      };
      printer = {
        kinematics = "cartesian";
        max_velocity = 300;
        max_accel = 3000;
        minimum_cruise_ratio = 0.5;
        max_z_velocity = 5;
        max_z_accel = 100;
        square_corner_velocity = 5;
      };
      stepper_x = {
        step_pin = "PC2";
        dir_pin = "PB9";
        enable_pin = "!PC3";
        microsteps = 16;
        rotation_distance = 40;
        endstop_pin = "^PA5";
        position_endstop = 0;
        position_max = 235;
        position_min = -15;
        homing_speed = 50;
      };
      stepper_y = {
        step_pin = "PB8";
        dir_pin = "PB7";
        enable_pin = "!PC3";
        microsteps = 16;
        rotation_distance = 40;
        endstop_pin = "^PA6";
        position_endstop = 0;
        position_max = 235;
        position_min = -13;
        homing_speed = 50;
      };
      stepper_z = {
        step_pin = "PB6";
        dir_pin = "!PB5";
        enable_pin = "!PC3";
        microsteps = 16;
        rotation_distance = 8;
        endstop_pin = "probe:z_virtual_endstop";
        position_max = 250;
        position_min = -4;
        homing_speed = 4;
        second_homing_speed = 1;
        homing_retract_dist = 2.0;
      };
      extruder = {
        max_extrude_only_distance = 100.0;
        step_pin = "PB4";
        dir_pin = "PB3";
        enable_pin = "!PC3";
        microsteps = 16;
        gear_ratio = "3.5:1";
        rotation_distance = 26.359;
        nozzle_diameter = 0.400;
        filament_diameter = 1.750;
        heater_pin = "PA1";
        sensor_type = "EPCOS 100K B57560G104F";
        sensor_pin = "PC5";
        control = "pid";
        pid_kp = 20.975;
        pid_ki = 1.260;
        pid_kd = 87.307;
        min_temp = 0;
        max_temp = 300;
        min_extrude_temp = 170;
        max_extrude_cross_section = 5;
        # Multiple pressure_advance values - you'd need to choose one
        pressure_advance = 0.0369; # Polymaker PLA Pro Teal
        # pressure_advance = 0.0465; # Overture PLA White
        pressure_advance_smooth_time = 0.04;
      };
      bltouch = {
        sensor_pin = "^PB1";
        control_pin = "PB0";
        x_offset = -31.8;
        y_offset = -40.5;
        z_offset = 3.65;
        speed = 35;
        samples = 3;
        samples_result = "median";
        samples_tolerance = 0.0075;
        samples_tolerance_retries = 10;
        stow_on_each_sample = false;
      };
      safe_z_home = {
        home_xy_position = "147, 154";
        speed = 75;
        z_hop = 10;
        z_hop_speed = 5;
        move_to_previous = true;
      };
      pause_resume.recover_velocity = 25;
      heater_bed = {
        heater_pin = "PA2";
        sensor_type = "EPCOS 100K B57560G104F";
        sensor_pin = "PC4";
        control = "pid";
        pid_kp = 66.288;
        pid_ki = 0.607;
        pid_kd = 1809.671;
        min_temp = 0;
        max_temp = 130;
      };
      fan.pin = "PA0";
      bed_screws = {
        screw1 = "25, 205";
        screw1_name = "rear left screw";
        screw2 = "195, 205";
        screw2_name = "rear right screw";
        screw3 = "195, 35";
        screw3_name = "front right screw";
        screw4 = "25, 35";
        screw4_name = "front left screw";
      };
      screws_tilt_adjust = {
        screw1 = "57, 229";
        screw1_name = "rear left screw";
        screw2 = "227, 229";
        screw2_name = "rear right screw";
        screw3 = "227, 70";
        screw3_name = "front right screw";
        screw4 = "57, 70";
        screw4_name = "front left screw";
        horizontal_move_z = 10;
        speed = 50;
        screw_thread = "CW-M4";
      };
      bed_mesh = {
        speed = 120;
        horizontal_move_z = 8;
        mesh_min = "15,15";
        mesh_max = "188,186";
        probe_count = "7,7";
        algorithm = "bicubic";
        fade_start = 1;
        fade_end = 10;
        fade_target = 0;
      };

      # idle_timeout = {
      #   gcode = ''
      #     {% if printer.pause_resume.is_paused %}
      #       M118 Idle timeout while paused, turning off hotend
      #       SET_HEATER_TEMPERATURE HEATER=extruder TARGET=0
      #     {% else %}
      #       M118 Idle timeout
      #       TURN_OFF_HEATERS
      #       M84
      #     {% endif %}
      #   '';
      #   timeout = 1800;
      # };

      # Optional input_shaper configurations (multiple options in original)
      # input_shaper = {
      #   # MANUAL SETUP
      #   shaper_freq_x = 54.85;
      #   shaper_type_x = "ei";
      #   shaper_freq_y = 57.52;
      #   shaper_type_y = "mzv";
      #
      #   # OR ADXL345 SETUP
      #   # shaper_freq_x = 68.8;
      #   # shaper_type_x = "mzv";
      #   # shaper_freq_y = 44.4;
      #   # shaper_type_y = "mzv";
      # };

      # Optional ADXL345 configuration
      # mcu_rpi = {
      #   serial = "/tmp/klipper_host_mcu";
      # };
      #
      # adxl345 = {
      #   cs_pin = "rpi:None";
      # };
      #
      # resonance_tester = {
      #   accel_chip = "adxl345";
      #   probe_points = "117, 117, 20";
      # };
    };
    firmwares.mcu = {
      enable = true;
      enableKlipperFlash = true;
      configFile = ./klipper-config;
      inherit serial;
    };
  };
}
