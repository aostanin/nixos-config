{ config, pkgs, ... }:

{
  services.telegraf = {
    enable = true;
    extraConfig = {
      inputs = {
        cpu = { totalcpu = true; };
        disk = {}; # TODO: ignore_fs = ["tmpfs", "devtmpfs", "devfs"]
        diskio = {}; # TODO: skip_serial_number = false?
        docker = { endpoint = "unix:///var/run/docker.sock"; }; # TODO: need to config?
        interrupts = {};
        #ipmi_sensor = {};
        kernel = {};
        mem = {};
        net = { interfaces = [ "enp2s0" ]; };
        netstat = {};
        processes = {};
        sensors = {};
        smart = { use_sudo = true; };
        swap = {};
        system = {};
        zfs = { poolMetrics = true; };
      };
      outputs = {
        influxdb = {
          database = "telegraf";
          urls = [ "http://localhost:8086" ];
        };
      };
    };
  };

  users.users.telegraf.extraGroups = [
    "docker"
  ];

  security.sudo.extraRules = [
    {
      commands = [
        {
          command = "${pkgs.smartmontools}/bin/smartctl";
          options = [ "NOPASSWD" ];
        }
      ];
      users = [ "telegraf" ];
    }
  ];

  systemd.services.telegraf.path = with pkgs; [
    lm_sensors
    smartmontools
    "/run/wrappers"
  ];
}
