{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.localModules.scrutinyCollector;
  secrets = import ../../secrets;
in {
  options.localModules.scrutinyCollector = {
    enable = mkEnableOption "scrutiny-collector";

    config = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Scrutiny config.
      '';
    };

    timerConfig = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Override the systemd timer config.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      configFile = pkgs.writeTextFile {
        name = "scrutiny.yaml";
        text = lib.generators.toYAML {} cfg.config;
      };
    in {
      systemd = {
        timers.scrutiny-collector = {
          wantedBy = ["timers.target"];
          partOf = ["scrutiny-collector.service"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
          timerConfig =
            {
              OnCalendar = "daily";
              Persistent = true;
              RandomizedDelaySec = "15m";
            }
            // cfg.timerConfig;
        };
        services.scrutiny-collector = {
          serviceConfig.Type = "oneshot";
          after = ["network-online.target"];
          wants = ["network-online.target"];
          script = ''
            ${pkgs.scrutiny}/bin/collector-metrics run \
              --config ${configFile} \
              --api-endpoint http://${secrets.network.zerotier.hosts.elena.address}:8081 \
              --host-id ${config.networking.hostName}
          '';
        };
      };
    }
  );
}
