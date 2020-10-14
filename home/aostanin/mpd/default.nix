{ pkgs, config, lib, ... }:
let
  secrets = import ../../../secrets;
in
{
  home.packages = with pkgs; [
    ncmpcpp
  ];

  xdg.configFile."ncmpcpp/config".text = ''
    mpd_host = ${secrets.network.home.hosts.elena.address}
    user_interface = alternative
  '';

  # TODO: Not in 20.03 branch yet
  # programs.ncmpcpp = {
  #   enable = true;
  #   settings = {
  #     mpd_host = secrets.network.home.hosts.elena.address;
  #     user_interface = "alternative";
  #   };
  # };
}
