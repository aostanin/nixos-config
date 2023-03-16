{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
in {
  services.zrepl = {
    enable = true;
    settings = {
      jobs = [
        {
          name = "snap-frequent";
          type = "snap";
          filesystems = {
            "rpool/appdata<" = true;
            "rpool/appdata/temp<" = false;
            "rpool/home<" = true;
            "rpool/root<" = true;
            "rpool/virtualization<" = true;
            "rpool/virtualization/docker<" = false;
          };
          snapshotting = {
            type = "cron";
            cron = "0 * * * *";
            prefix = "zrepl_";
            timestamp_format = "iso-8601";
          };
          pruning = {
            keep = [
              {
                type = "grid";
                grid = "1x1h(keep=all) | 24x1h | 14x1d";
                regex = "^zrepl_.*";
              }
              {
                type = "regex";
                negate = true;
                regex = "^zrepl_.*";
              }
            ];
          };
        }
        {
          type = "source";
          name = "source";
          serve = {
            type = "tcp";
            listen = ":8889";
            clients = {
              "${secrets.network.zerotier.hosts.rpi-backup.address}" = "rpi-backup";
            };
          };
          send.encrypted = false;
          filesystems = {
            "rpool/appdata<" = true;
            "rpool/appdata/temp<" = false;
            "rpool/home<" = true;
            "rpool/root<" = true;
            "rpool/root/nix<" = false;
            "rpool/virtualization<" = true;
            "rpool/virtualization/docker<" = false;
          };
          snapshotting.type = "manual";
        }
      ];
    };
  };
}
