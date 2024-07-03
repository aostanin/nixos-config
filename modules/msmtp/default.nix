{
  config,
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
    sops.secrets."email/password".owner = secrets.user.username;

    programs.msmtp = {
      enable = true;
      accounts.default = {
        inherit (secrets.email) host port user;
        tls = true;
        tls_starttls = true;
        auth = true;
        from = "${config.networking.hostName}@${secrets.email.domain}";
        passwordeval = "cat ${config.sops.secrets."email/password".path}";
      };
    };
  };
}
