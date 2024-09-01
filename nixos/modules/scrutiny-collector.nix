{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  cfg = config.localModules.scrutinyCollector;
in {
  options.localModules.scrutinyCollector = {
    enable = lib.mkEnableOption "scrutiny-collector";

    config = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Scrutiny config.
      '';
    };

    timerConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Override the systemd timer config.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
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
            ${lib.getExe' pkgs.scrutiny "collector-metrics"} run \
              --config ${configFile} \
              --api-endpoint ${secrets.scrutiny.baseUrl} \
              --host-id ${config.networking.hostName}
          '';
        };
      };
    }
  );
}
