let
  pkgs = import <nixpkgs> {};
  stateVersion = "19.09";
  nixPath = [
    "nixpkgs=https://github.com/NixOS/nixpkgs/archive/299fbcbb8b59a7d3f88d4b018dcee34ed59ee45a.tar.gz"
    "home-manager=https://github.com/rycee/home-manager/archive/f5c9303cedd67a57121f0cbe69b585fb74ba82d9.tar.gz"
    "nixos-hardware=https://github.com/NixOS/nixos-hardware/archive/89c4ddb0e60e5a643ab15f68b2f4ded43134f492.tar.gz"
  ];
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    nixops
  ];

  shellHook = ''
    export NIX_PATH="${builtins.concatStringsSep ":" (nixPath ++ [ "." ])}"
    export NIXOPS_STATE=state.nixops

    function our_create () {
      if [ `nixops list | grep -c $1` -eq 0 ]; then
        (set -x; nixops create --deployment $1 "<$1.nix>")
      fi
      nixops set-args --arg nixPath '[ "${builtins.concatStringsSep "\" \"" nixPath}" ]' -d $1
    }

    our_create network
  '';
}
