{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
in {
  services.rsync-backup = {
    enable = true;
    backups = {
      vps-gce1 = {
        source = "root@${secrets.network.zerotier.hosts.vps-gce1.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-gce1";
      };
      vps-oci1 = {
        source = "root@${secrets.network.zerotier.hosts.vps-oci1.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-oci1";
      };
      vps-oci2 = {
        source = "root@${secrets.network.zerotier.hosts.vps-oci2.address}:/storage/appdata";
        destination = "/storage/backup/hosts/dir/vps-oci2";
      };
    };
  };

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
            "vmpool/appdata<" = true;
            "vmpool/virtualization<" = true;
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
          name = "snap-infrequent";
          type = "snap";
          filesystems = {
            "tank/appdata<" = true;
            "tank/backup<" = true;
            "tank/backup/hosts/zfs<" = false;
            "tank/download<" = true;
            "tank/media<" = true;
            "tank/personal<" = true;
            "tank/virtualization<" = true;
          };
          snapshotting = {
            type = "periodic";
            interval = "12h";
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
          type = "push";
          name = "local-push";
          connect = {
            type = "tcp";
            address = "127.0.0.1:8888";
          };
          filesystems = {
            "rpool/appdata<" = true;
            "rpool/appdata/temp<" = false;
            "rpool/home<" = true;
            "rpool/root<" = true;
            "rpool/virtualization<" = true;
            "rpool/virtualization/docker<" = false;
            "vmpool/appdata<" = true;
            "vmpool/virtualization<" = true;
          };
          snapshotting.type = "manual";
          pruning = {
            keep_sender = [
              {
                type = "regex";
                regex = ".*";
              }
            ];
            keep_receiver = [
              {
                type = "grid";
                grid = "1x1h(keep=all) | 24x1h | 90x1d";
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
          type = "sink";
          name = "sink";
          serve = {
            type = "tcp";
            listen = ":8888";
            listen_freebind = true;
            clients = {
              "127.0.0.1" = "elena";
              "${secrets.network.zerotier.hosts.roan.address}" = "roan";
              "${secrets.network.zerotier.hosts.mareg.address}" = "mareg";
            };
          };
          recv = {
            placeholder.encryption = "inherit";
          };
          root_fs = "tank/backup/hosts/zfs";
        }
      ];
    };
  };

  systemd = {
    timers.zrepl-local-push = {
      wantedBy = ["timers.target"];
      partOf = ["zrepl-local-push.service"];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "5h";
      };
    };
    services.zrepl-local-push = {
      serviceConfig.Type = "oneshot";
      script = "${pkgs.zrepl}/bin/zrepl signal wakeup local-push";
    };
  };
}
