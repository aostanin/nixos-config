{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.karabiner-elements;
in {
  options.localModules.karabiner-elements = {
    enable = lib.mkEnableOption "karabiner-elements";
  };

  config = lib.mkIf cfg.enable {
    # TODO: Currently broken https://github.com/nix-darwin/nix-darwin/issues/1041
    services.karabiner-elements.enable = false;
  };
}
