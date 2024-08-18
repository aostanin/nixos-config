{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.containers;
in {
  options.localModules.containers = {
    enable = lib.mkEnableOption "containers";

    # TODO: Home directory option
  };

  config = lib.mkIf cfg.enable {
    localModules.docker = {
      enable = true;
      usePodman = true;
    };

    localModules.redir = {
      http = {
        src = ":80";
        dst = ":8080";
      };
      https = {
        src = ":443";
        dst = ":8443";
      };
    };

    users = {
      users.container = {
        isNormalUser = true;
        group = "container";
        openssh.authorizedKeys.keys = [secrets.user.sshKey secrets.containers.sshKey];
      };

      groups.container = {};
    };
  };
}
