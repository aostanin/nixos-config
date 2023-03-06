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
      {id = "dbepggeogbaibhgnhhndojpepiihcmeb";} # Vimium
    ];
  };
}
