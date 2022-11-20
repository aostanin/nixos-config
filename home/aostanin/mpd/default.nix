{
  pkgs,
  config,
  lib,
  ...
}: let
  secrets = import ../../../secrets;
in {
  programs.ncmpcpp = {
    enable = true;
    settings = {
      mpd_host = secrets.network.home.hosts.elena.address;
      user_interface = "alternative";
    };
  };
}
