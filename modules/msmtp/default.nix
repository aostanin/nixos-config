{
  config,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
in {
  programs.msmtp = {
    enable = true;
    accounts.default = {
      tls = true;
      tls_starttls = true;
      auth = true;
      host = secrets.email.host;
      port = secrets.email.port;
      user = secrets.email.username;
      password = secrets.email.password;
    };
  };
}
