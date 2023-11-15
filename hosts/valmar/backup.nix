{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: {
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
          type = "push";
          name = "push";
          connect = {
            type = "tcp";
            address = "${secrets.network.storage.hosts.elena.address}:8888";
          };
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
      wants = ["network-online.target"];
      timerConfig = {
        OnCalendar = "*-*-* 01:15:00";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
    services.zrepl-push = {
      serviceConfig.Type = "oneshot";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      script = "${pkgs.zrepl}/bin/zrepl signal wakeup push";
    };
  };
}
