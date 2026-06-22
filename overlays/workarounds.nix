final: prev: {
  # direnv tests fail on darwin (fish test)
  # ref: https://github.com/NixOS/nixpkgs/issues/507531
  direnv = prev.direnv.overrideAttrs (_: {doCheck = false;});

  # Blockstream Jade needs cbor2
  hwi = prev.hwi.overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [prev.python3Packages.cbor2];
  });

  # meshcentral's bundled node-gyp (8.4.1) imports distutils, removed in
  # Python 3.12; building the native bufferutil dep fails. Give node-gyp a
  # Python with setuptools (restores the distutils shim). Surfaces on aarch64
  # since x86 is cached.
  meshcentral = prev.meshcentral.overrideAttrs (old: let
    python = final.python3.withPackages (ps: [ps.setuptools]);
  in {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [python];
    npm_config_python = "${python}/bin/python3";
  });
}
