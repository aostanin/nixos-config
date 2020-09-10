{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs; [
    ncmpcpp
  ];

  xdg.configFile."ncmpcpp/config".text = ''
    mpd_host = elena.lan
    user_interface = alternative
  '';

  # TODO: Not in 20.03 branch yet
  # programs.ncmpcpp = {
  #   enable = true;
  #   settings = {
  #     mpd_host = "elena.lan";
  #     user_interface = "alternative";
  #   };
  # };
}
