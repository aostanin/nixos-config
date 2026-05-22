{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.localModules.television;
in {
  options.localModules.television = {
    enable = lib.mkEnableOption "television";
  };

  config = lib.mkIf cfg.enable {
    programs.television = {
      enable = true;
      package = pkgs.unstable.television;
      enableZshIntegration = false;
    };

    xdg.configFile = let
      cableDir = "${config.programs.television.package.src}/cable/unix";
    in
      lib.mapAttrs' (
        name: _:
          lib.nameValuePair "television/cable/${name}" {
            source = "${cableDir}/${name}";
          }
      ) (builtins.readDir cableDir);
  };
}
