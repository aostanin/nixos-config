{
  config,
  lib,
  pkgs,
  secrets,
  ...
}: let
  cfg = config.localModules.home-router;
  inherit (secrets.network.networks) lan guest iot;
  systemctl = "${pkgs.systemd}/bin/systemctl";
  ndiscHandover = pkgs.writers.writePython3 "home-router-ndisc-handover" {flakeIgnore = ["E501"];} (builtins.readFile ./ndisc-handover.py);

  # Debounced demote: keepalived dips through BACKUP on every restart, so
  # notify_backup only arms a timer that notify_master cancels.
  notifyScript = pkgs.writeShellScript "home-router-notify" ''
    case "$1" in
      master)
        ${systemctl} stop home-router-demote.timer home-router-demote.service
        ${systemctl} --no-block start home-router-active.target
        # Re-announce even if the data plane never stopped: a demotion cut
        # short may already have sent the goodbye RA, and a peer that briefly
        # held the VIPs has pointed the upstream neighbour cache at itself.
        ${systemctl} --no-block try-restart dnsmasq.service
        ${systemctl} --no-block restart home-router-na-refresh.service
        ;;
      backup | fault)
        ${systemctl} --no-block start home-router-demote.timer
        ;;
    esac
  '';
in {
  options.localModules.home-router = {
    isMaster = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run as VRRP master (else backup); sets state and default priority.";
    };

    priority = lib.mkOption {
      type = lib.types.ints.between 1 254;
      default =
        if cfg.isMaster
        then 200
        else 100;
      description = "VRRP priority; the highest live node holds the VIPs.";
    };
  };

  config = lib.mkIf cfg.enable {
    # let coredns bind the VIPs even on the backup, where they're not present
    boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

    systemd.targets.home-router-active.description = "Home router active (VRRP master) data plane";

    systemd.services =
      lib.genAttrs ["dnsmasq" "ndppd" "lan-prefix"] (_: {
        wantedBy = lib.mkForce ["home-router-active.target"];
        partOf = ["home-router-active.target"];
      })
      // {
        home-router-demote = {
          description = "Stop home-router active data plane (VRRP demotion)";
          serviceConfig.Type = "oneshot";
          script = ''
            ${ndiscHandover} goodbye-ra ${lan.interface} || true
            ${systemctl} stop home-router-active.target
            # drop the floating GUA (a oneshot stop won't undo the add)
            ${pkgs.iproute2}/bin/ip -6 addr flush dev ${lan.interface} scope global || true
          '';
        };

        home-router-na-refresh = {
          description = "Point the upstream neighbour cache at this node after a VRRP promotion";
          wantedBy = ["home-router-active.target"];
          partOf = ["home-router-active.target"];
          path = [pkgs.iproute2 pkgs.conntrack-tools];
          script = "${ndiscHandover} refresh-na ${cfg.wanInterface} ${lan.interface} 60";
        };
      };
    systemd.timers.lan-prefix = {
      wantedBy = lib.mkForce ["home-router-active.target"];
      partOf = ["home-router-active.target"];
    };
    systemd.timers.home-router-demote = {
      wantedBy = [];
      timerConfig = {
        OnActiveSec = "5s";
        AccuracySec = "1s";
      };
    };

    services.keepalived = {
      enable = true;
      vrrpInstances.lan = {
        interface = lan.interface;
        state =
          if cfg.isMaster
          then "MASTER"
          else "BACKUP";
        virtualRouterId = 51;
        inherit (cfg) priority;
        virtualIps = [
          {
            addr = "${lan.prefix}.1/24";
            dev = lan.interface;
          }
          {
            addr = "${guest.prefix}.1/24";
            dev = guest.interface;
          }
          {
            addr = "${iot.prefix}.1/24";
            dev = iot.interface;
          }
        ];
        extraConfig = ''
          notify_master "${notifyScript} master"
          notify_backup "${notifyScript} backup"
          notify_fault "${notifyScript} fault"
        '';
      };
    };
  };
}
