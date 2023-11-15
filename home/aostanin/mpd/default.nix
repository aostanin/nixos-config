{
  pkgs,
  config,
  lib,
  secrets,
  ...
}: {
  programs.ncmpcpp = {
    enable = true;
    settings = {
      mpd_host = secrets.network.home.hosts.tio.address;
      user_interface = "alternative";
    };
  };
}
