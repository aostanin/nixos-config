let
  pkgs = import <nixpkgs> { };
  stateVersion = "19.09";
  nixPath = import ./path.nix;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    cargo
    nixops
    pre-commit
  ];

  lorriHook = ''
    export NIX_PATH="${builtins.concatStringsSep ":" (nixPath ++ [ "." ])}"
    export NIXOPS_STATE=state.nixops
    export NIX_STATE_VERSION="${stateVersion}"

    function our_create () {
      if [ `nixops list | grep -c $1` -eq 0 ]; then
        (set -x; nixops create --deployment $1 "<$1.nix>")
      fi
      nixops set-args --arg nixPath '[ "${builtins.concatStringsSep "\" \"" nixPath}" ]' -d $1
      nixops set-args --argstr stateVersion '${stateVersion}' -d $1
    }

    our_create network
  '';
}
