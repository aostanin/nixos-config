{
  config,
  pkgs,
  lib,
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
            address = "[${secrets.network.zerotier.hosts.elena.address6}]:8888";
          };
          send.encrypted = true;
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
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
    services.zrepl-push = {
      serviceConfig = {
        Type = "oneshot";
        ExecCondition = pkgs.writeShellScript "check_home_network" ''
          status=$(${lib.getExe' pkgs.iproute2 "ip"} neigh show to ${secrets.network.home.hosts.router.address} nud reachable | grep "${secrets.network.home.hosts.router.macAddress}")
          if [ -z "$status" ]; then
            exit 1
          else
            exit 0
          fi
        '';
      };
      after = ["network-online.target"];
      wants = ["network-online.target"];
      script = ''
        # TODO: Wake up elena
        ${lib.getExe pkgs.zrepl} signal wakeup push
      '';
    };
  };
}
