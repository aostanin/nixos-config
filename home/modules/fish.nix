{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.fish;
in {
  options.localModules.fish = {
    enable = lib.mkEnableOption "fish";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        fish_vi_key_bindings
      '';
    };
  };
}
