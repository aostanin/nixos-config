{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.localModules.chromium;
in {
  options.localModules.chromium = {
    enable = lib.mkEnableOption "chromium";
  };

  config = lib.mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      package = pkgs.chromium;
      extensions = [
        {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
        {id = "ophjlpahpchlmihnnnihgmmeilfjmjjc";} # LINE
        {id = "jipdnfibhldikgcjhfnomkfpcebammhp";} # rikaikun
        {id = "dbepggeogbaibhgnhhndojpepiihcmeb";} # Vimium
      ];
    };
  };
}
