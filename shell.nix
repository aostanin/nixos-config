let
  pkgs = import <nixpkgs> { };
  stateVersion = import ./state-version.nix;
  nixPath = import ./path.nix;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    cargo # For nixpkgs-fmt
    git-crypt
    morph
    pre-commit
  ];

  lorriHook = ''
    export NIX_PATH="${builtins.concatStringsSep ":" (nixPath ++ [ "." ])}"
    export NIX_STATE_VERSION="${stateVersion}"

    pre-commit install -f --hook-type pre-commit
  '';
}
