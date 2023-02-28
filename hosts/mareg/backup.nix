{
  config,
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
            "rpool/home<" = true;
            "rpool/root<" = true;
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
            address = "${secrets.network.zerotier.hosts.elena.address}:8888";
          };
          send.encrypted = true;
          filesystems = {
            "rpool/home<" = true;
            "rpool/root<" = true;
            "rpool/root/nix<" = false;
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
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "5h";
      };
    };
    services.zrepl-push = {
      serviceConfig.Type = "oneshot";
      script = "${pkgs.zrepl}/bin/zrepl signal wakeup push";
    };
  };
}
