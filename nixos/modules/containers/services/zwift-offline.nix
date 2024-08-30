{
  lib,
  pkgs,
  config,
  secrets,
  ...
}: let
  name = "zwift-offline";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/zoffline/zoffline:latest";
      raw.ports = [
        "3024:3024/udp"
        "3025:3025"
      ];
      volumes.storage.destination = "/usr/src/app/zwift-offline/storage";
      raw.volumes = let
        serverIp = pkgs.writeTextFile {
          name = "server-ip.txt";
          text = secrets.network.home.hosts.${config.networking.hostName}.address;
        };
      in ["${serverIp}:/usr/src/app/zwift-offline/storage/server-ip.txt"];
      proxy = {
        enable = true;
        port = 443;
        scheme = "https";
        hosts = [
          "us-or-rly101.zwift.com"
          "secure.zwift.com"
          "cdn.zwift.com"
          "launcher.zwift.com"
        ];
      };
    };

    services.traefik.dynamicConfigOptions.tls.certificates = let
      zwift-offline = pkgs.fetchFromGitHub {
        owner = "zoffline";
        repo = "zwift-offline";
        rev = "zoffline_1.0.134206";
        sha256 = "sha256-B3kXIPWDIVcAzrqSR6HMtaSFMCAtRlCUyi1JvZdoyLQ=";
      };
    in [
      {
        certFile = "${zwift-offline}/ssl/cert-zwift-com.pem";
        keyFile = "${zwift-offline}/ssl/key-zwift-com.pem";
      }
    ];
  };
}
