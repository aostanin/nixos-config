let
  pkgs = import <nixpkgs> { };
  stateVersion = import ./state-version.nix;
  nixPath = import ./nix-path.nix;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    cargo # For nixpkgs-fmt
    git-crypt
    pre-commit
  ];

  lorriHook = ''
    pre-commit install -f --hook-type pre-commit
  '';
}
