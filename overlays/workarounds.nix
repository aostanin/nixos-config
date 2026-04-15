final: prev: {
  # direnv tests fail on darwin (fish test)
  # ref: https://github.com/NixOS/nixpkgs/issues/507531
  direnv = prev.direnv.overrideAttrs (_: {doCheck = false;});

  # Blockstream Jade needs cbor2
  hwi = prev.hwi.overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [prev.python3Packages.cbor2];
  });
}
