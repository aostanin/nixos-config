{
  lib,
  config,
  ...
}: let
  name = "stalwart";
  cfg = config.localModules.containers.services.${name};
in {
  options.localModules.containers.services.${name} = {
    enable = lib.mkEnableOption name;
  };

  config = lib.mkIf cfg.enable {
    localModules.containers.containers.${name} = {
      raw.image = "docker.io/stalwartlabs/stalwart:latest";
      raw.ports = [
        #"443:443" # HTTPS
        #"8080:8080" # HTTP Admin/API
        #"25:25" # SMTP
        #"587:587" # SMTP Submission
        #"465:465" # SMTP Submission (TLS)
        #"143:143" # IMAP
        #"993:993" # IMAP (TLS)
        #"4190:4190" # ManageSieve
        #"110:110" # POP3
        #"995:995" # POP3 (TLS)
      ];
      volumes = {
        data = {
          destination = "/opt/stalwart";
          parent = name;
        };
      };
      proxy = {
        enable = true;
        port = 8080;
      };
    };
  };
}
