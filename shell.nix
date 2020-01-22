let
  pkgs = import <nixpkgs> {};
  stateVersion = "19.09";
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    nixops
  ];

  shellHook = ''
    export NIX_PATH="\
    nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-${stateVersion}.tar.gz:\
    home-manager=https://github.com/rycee/home-manager/archive/release-${stateVersion}.tar.gz:\
    nixos-hardware=https://github.com/NixOS/nixos-hardware/archive/master.tar.gz:\
    ."
    export NIXOPS_STATE=state.nixops

    function our_create () {
      if [ `nixops list | grep -c $1` -eq 0 ]
      then
       (set -x; nixops create --deployment $1 "<$1.nix>")
      fi
    }

    our_create network
  '';
}
