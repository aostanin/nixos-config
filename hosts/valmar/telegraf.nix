{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
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
        kernel = { };
        mem = { };
        net = { }; # TODO: interfaces
        netstat = { };
        processes = { };
        sensors = { };
        smart = { use_sudo = true; };
        swap = { };
        system = { };
        zfs = { poolMetrics = true; };
      };
      outputs = {
        influxdb = {
          database = "telegraf";
          urls = [ "http://${secrets.network.home.hosts.elena.address}:8086" ];
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
