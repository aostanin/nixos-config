{
  config,
  pkgs,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.msmtp;
in {
  options.localModules.msmtp = {
    enable = lib.mkEnableOption "msmtp";
  };

  config = lib.mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      accounts.default = {
        tls = true;
        tls_starttls = true;
        auth = true;
        from = secrets.email.from;
        host = secrets.email.host;
        port = secrets.email.port;
        user = secrets.email.username;
        password = secrets.email.password;
      };
    };
  };
}
