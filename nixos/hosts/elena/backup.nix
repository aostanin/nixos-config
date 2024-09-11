{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: {
  sops.secrets."restic/ssh_key" = {};

  users = {
    users.backup = {
      isNormalUser = true;
      group = "backup";
      home = "/storage/backup/restic";
      openssh.authorizedKeys.keys = [secrets.restic.publicSshKey];
    };
    groups.backup = {};
  };

  sops.secrets."user/ssh_key" = {};

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
            "rpool/personal<" = true;
            "rpool/root<" = true;
            "rpool/virtualization<" = true;
            "rpool/virtualization/docker<" = false;
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
            type = "cron";
            cron = "0 1 * * *";
            prefix = "zrepl_";
            timestamp_format = "iso-8601";
          };
          pruning = {
            keep = [
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
            "rpool/personal<" = true;
            "rpool/root<" = true;
            "rpool/root/nix<" = false;
            "rpool/virtualization<" = true;
            "rpool/virtualization/docker<" = false;
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
          type = "push";
          name = "external-push";
          connect = {
            type = "tcp";
            address = "127.0.0.1:8889";
          };
          filesystems = {
            "rpool/appdata<" = true;
            "rpool/appdata/temp<" = false;
            "rpool/home<" = true;
            "rpool/personal<" = true;
            "rpool/root<" = true;
            "rpool/root/nix<" = false;
            "tank/media/audiobooks<" = true;
            "tank/media/books<" = true;
            "tank/media/music<" = true;
            "tank/personal<" = true;
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
            clients =
              {
                "127.0.0.1" = "elena";
              }
              // lib.mapAttrs' (n: v: lib.nameValuePair v.address n) secrets.network.tailscale.hosts;
          };
          recv = {
            placeholder.encryption = "inherit";
          };
          root_fs = "tank/backup/hosts/zfs";
        }
        {
          type = "sink";
          name = "sink-external";
          serve = {
            type = "tcp";
            listen = ":8889";
            listen_freebind = true;
            clients = {
              "127.0.0.1" = "elena";
            };
          };
          recv = {
            placeholder.encryption = "inherit";
          };
          root_fs = "external/backup/hosts/zfs";
        }
      ];
    };
  };

  systemd = {
    timers.zrepl-local-push = {
      wantedBy = ["timers.target"];
      partOf = ["zrepl-local-push.service"];
      timerConfig = {
        OnCalendar = "*-*-* 18:00:00";
        Persistent = true;
      };
    };
    services.zrepl-local-push = {
      serviceConfig.Type = "oneshot";
      script = "${lib.getExe pkgs.zrepl} signal wakeup local-push";
    };
  };
}
