{
  config,
  lib,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
in {
  # TODO: Refactor into module
  services.zrepl = {
    enable = true;
    settings = {
      jobs = [
        {
          name = "snap-frequent";
          type = "snap";
          filesystems = {
            "rpool/appdata<" = true;
            "rpool/home<" = true;
            "rpool/root<" = true;
            "rpool/virtualization<" = true;
            "rpool/virtualization/docker<" = false;
          };
          snapshotting = {
            type = "periodic";
            interval = "15m";
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
          name = "push";
          connect = {
            type = "tcp";
            address = "${secrets.network.storage.hosts.elena.address}:8888";
          };
          send.encrypted = false;
          filesystems = {
            "rpool/appdata<" = true;
            "rpool/home<" = true;
            "rpool/root<" = true;
            "rpool/root/nix<" = false;
            "rpool/virtualization<" = true;
            "rpool/virtualization/docker<" = false;
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
          type = "pull";
          name = "pull-elena";
          connect = {
            type = "tcp";
            address = "${secrets.network.storage.hosts.elena.address}:8889";
          };
          recv = {
            placeholder.encryption = "inherit";
          };
          root_fs = "tank/backup/hosts/zfs/elena";
          interval = "manual";
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
      ];
    };
  };

  systemd = {
    timers.zrepl-push = {
      wantedBy = ["timers.target"];
      partOf = ["zrepl-push.service"];
      after = ["network-online.target"];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "5h";
      };
    };
    services.zrepl-push = {
      serviceConfig.Type = "oneshot";
      script = "${pkgs.zrepl}/bin/zrepl signal wakeup push";
    };

    timers.zrepl-pull-elena = {
      wantedBy = ["timers.target"];
      partOf = ["zrepl-pull-elena.service"];
      after = ["network-online.target"];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "5h";
      };
    };
    services.zrepl-pull-elena = {
      serviceConfig.Type = "oneshot";
      script = "${pkgs.zrepl}/bin/zrepl signal wakeup pull-elena";
    };
  };
}
