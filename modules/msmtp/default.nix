{
  config,
  pkgs,
  secrets,
  ...
}: {
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
}
