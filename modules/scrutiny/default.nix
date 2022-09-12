{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
{
  systemd = {
    timers.scrutiny-collector = {
      wantedBy = [ "timers.target" ];
      partOf = [ "scrutiny-collector.service" ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "5h";
      };
    };
    services.scrutiny-collector = {
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker run --rm \
          -v /run/udev:/run/udev:ro \
          --cap-add SYS_RAWIO \
          --cap-add SYS_ADMIN \
          $(find /dev \( -name "sd[a-z]" -o -name "nvme[0-9]" \) -printf "--device=%p ") \
          -e SCRUTINY_API_ENDPOINT=http://${secrets.network.home.hosts.elena.address}:8081 \
          -e COLLECTOR_HOST_ID=${config.networking.hostName} \
          --name scrutiny-collector \
          ghcr.io/analogj/scrutiny:master-collector \
          /opt/scrutiny/bin/scrutiny-collector-metrics run
      '';
    };
  };
}
