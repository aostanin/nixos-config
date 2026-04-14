{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.localModules.hammerspoon;

  apple-click-through = pkgs.fetchFromGitHub {
    owner = "dainank";
    repo = "apple-click-through";
    rev = "703ed93725ed7744b2e7ddf661e5717d25cc8dbc";
    hash = "sha256-95bCMOXYVucmqvzoELPnd1OmUnjS5/sjZrOUJGxgasU=";
  };
in {
  options.localModules.hammerspoon = {
    enable = lib.mkEnableOption "hammerspoon";
  };

  config = lib.mkIf cfg.enable {
    home.file.".hammerspoon/init.lua".source = "${apple-click-through}/init.lua";
  };
}
