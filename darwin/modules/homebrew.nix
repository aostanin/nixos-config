{
  config,
  pkgs,
  lib,
  inputs,
  secrets,
  ...
}: let
  cfg = config.localModules.homebrew;
in {
  options.localModules.homebrew = {
    enable = lib.mkEnableOption "homebrew";
  };

  config = lib.mkIf cfg.enable {
    nix-homebrew = {
      enable = true;
      enableRosetta = pkgs.stdenv.hostPlatform.system == "aarch64-darwin";
      user = secrets.user.username;
      mutableTaps = false;
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
      };
      extraEnv = {
        HOMEBREW_NO_ANALYTICS = "1";
      };
    };

    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      taps = builtins.attrNames config.nix-homebrew.taps;
      brews = [
      ];
      casks = [
        "caffeine"
        {
          name = "chromium";
          args.no_quarantine = true;
        }
        "claude"
        "element"
        "hammerspoon"
        "middleclick"
        "insta360-studio"
        "sol"
        "tailscale-app"
      ];
      masApps = {
        Xcode = 497799835;
      };
    };
  };
}
