{
  pkgs,
  config,
  lib,
  ...
}: {
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
}
