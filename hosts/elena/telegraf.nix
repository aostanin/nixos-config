{ config, pkgs, ... }:

{
  services.telegraf = {
    enable = true;
    extraConfig = {
      inputs = {
        cpu = { totalcpu = true; };
        disk = { }; # TODO: ignore_fs = ["tmpfs", "devtmpfs", "devfs"]
        diskio = {
          devices = [ "sd[a-z]" ];
          skip_serial_number = false;
        };
        docker = { endpoint = "unix:///var/run/docker.sock"; };
        interrupts = { };
        ipmi_sensor = {
          interval = "30s";
          timeout = "20s";
          use_sudo = true;
        };
        kernel = { };
        mem = { };
        net = { }; # TODO: interfaces
        netstat = { };
        processes = { };
        sensors = { };
        smart = { use_sudo = true; };
        swap = { };
        system = { };
        temp = { };
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
          command = "${pkgs.ipmitool}/bin/ipmitool";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.smartmontools}/bin/smartctl";
          options = [ "NOPASSWD" ];
        }
      ];
      users = [ "telegraf" ];
    }
  ];

  systemd.services.telegraf.path = with pkgs; [
    ipmitool
    lm_sensors
    smartmontools
    "/run/wrappers"
  ];
}
