{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
{
  services.ssmtp = {
    enable = true;
    useTLS = true;
    useSTARTTLS = true;
    domain = secrets.email.domain;
    hostName = "${secrets.email.host}:${toString secrets.email.port}";
    authUser = secrets.email.username;
    settings = {
      AuthPass = secrets.email.password;
    };
  };
}
