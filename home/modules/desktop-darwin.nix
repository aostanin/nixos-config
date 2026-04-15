{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.desktop-darwin;
in {
  options.localModules.desktop-darwin = {
    enable = lib.mkEnableOption "desktop-darwin";
  };

  config = lib.mkIf cfg.enable {
    localModules = {
      "3dprinting".enable = lib.mkDefault true;
      alacritty.enable = lib.mkDefault true;
      firefox.enable = lib.mkDefault true;
      hammerspoon.enable = lib.mkDefault true;
      karabiner-elements.enable = lib.mkDefault true;
      syncthing.enable = lib.mkDefault true;
    };

    # Workaround for Ctrl+/ triggering system alert sound in Alacritty and other apps
    # ref: https://github.com/alacritty/alacritty/issues/3014#issuecomment-1659329460
    home.file."Library/KeyBindings/DefaultKeyBinding.dict".text = ''
      {
          "^/" = "noop:";
      }
    '';

    home.packages = with pkgs; [
      alt-tab-macos
      flameshot
      ice-bar
      scroll-reverser
      thunderbird
      utm

      # Chat
      discord
      slack
    ];

    # TODO: Switch to services.flameshot once it's in stable home-manager
    # ref: https://github.com/nix-community/home-manager/pull/8730
    launchd.agents.flameshot = {
      enable = true;
      config = {
        ProgramArguments = [(lib.getExe pkgs.flameshot)];
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Interactive";
        RunAtLoad = true;
      };
    };

    services.ollama = {
      enable = true;
      package = pkgs.unstable.ollama;
    };
  };
}
