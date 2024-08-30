{
  lib,
  config,
  ...
}: let
  name = "adguardhome";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;

    dnsListenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
    };

    dnsPort = lib.mkOption {
      type = lib.types.int;
      default = 53;
    };
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/adguard/adguardhome:latest";
      raw.ports = [
        "${cfg.dnsListenAddress}:${toString cfg.dnsPort}:53/tcp"
        "${cfg.dnsListenAddress}:${toString cfg.dnsPort}:53/udp"
      ];
      volumes = {
        work.destination = "/opt/adguardhome/work";
        conf.destination = "/opt/adguardhome/conf";
      };
      proxies = {
        "adguard" = {
          enable = true;
          port = 80;
        };
        "${name}-admin" = {
          enable = true;
          port = 3000;
        };
      };
    };
  };
}
