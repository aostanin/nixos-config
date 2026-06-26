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

  # Debounced demote: keepalived dips through BACKUP on every restart, so
  # notify_backup only arms a timer that notify_master cancels.
  notifyScript = pkgs.writeShellScript "home-router-notify" ''
    case "$1" in
      master)
        ${systemctl} stop home-router-demote.timer home-router-demote.service
        ${systemctl} --no-block start home-router-active.target
        ;;
      backup | fault)
        ${systemctl} --no-block start home-router-demote.timer
        ;;
    esac
  '';
in {
  options.localModules.home-router.isMaster = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Run as VRRP master (else backup); sets state and priority.";
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
            ${systemctl} stop home-router-active.target
            # drop the floating GUA (a oneshot stop won't undo the add)
            ${pkgs.iproute2}/bin/ip -6 addr flush dev ${lan.interface} scope global || true
          '';
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
        state = if cfg.isMaster then "MASTER" else "BACKUP";
        virtualRouterId = 51;
        priority = if cfg.isMaster then 200 else 100;
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
