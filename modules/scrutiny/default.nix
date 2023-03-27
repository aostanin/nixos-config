{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.scrutiny;
  secrets = import ../../secrets;
in {
  options.services.scrutiny = {
    enable = mkEnableOption "scrutiny";

    disks = mkOption {
      type = types.listOf types.str;
      default = ["/dev/sd[a-z]" "/dev/nvme[0-9]"];
      description = ''
        Full path to the disks to monitor.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      timers.scrutiny-collector = {
        wantedBy = ["timers.target"];
        partOf = ["scrutiny-collector.service"];
        after = ["network-online.target"];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
      };
      services.scrutiny-collector = {
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.docker}/bin/docker run --rm \
            -v /run/udev:/run/udev:ro \
            --cap-add SYS_RAWIO \
            --cap-add SYS_ADMIN \
            $(find /dev \( ${lib.concatStringsSep " -o " (map (disk: "-wholename \"${disk}\"") cfg.disks)} \) -printf "--device=%p ") \
            -e SCRUTINY_API_ENDPOINT=http://${secrets.network.zerotier.hosts.tio.address}:8081 \
            -e COLLECTOR_HOST_ID=${config.networking.hostName} \
            --name scrutiny-collector \
            ghcr.io/analogj/scrutiny:master-collector \
            /opt/scrutiny/bin/scrutiny-collector-metrics run
        '';
      };
    };
  };
}
