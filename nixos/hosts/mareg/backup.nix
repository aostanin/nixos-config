{
  pkgs,
  lib,
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
            "rpool/system<" = true;
            "rpool/user<" = true;
          };
          snapshotting = {
            type = "periodic";
            interval = "1h";
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
            address = "elena:8888";
          };
          filesystems = {
            "rpool/system<" = true;
            "rpool/user<" = true;
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
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
    services.zrepl-push = {
      serviceConfig.Type = "oneshot";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      script = "${lib.getExe pkgs.zrepl} signal wakeup push";
    };
  };
}