{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  perl,
  python3,
  xcodeenv,
  xcodeWrapperArgs ? {},
  xcodeWrapper ? xcodeenv.composeXcodeWrapper xcodeWrapperArgs,
}: let
  pythonEnv = python3.withPackages (ps:
    with ps; [
      cryptography
      hf-xet
      httpx
      huggingface-hub
      jinja2
      jsonschema
      llguidance
      numpy
      pillow
      pypdfium2
      pyyaml
      referencing
      regex
      safetensors
      tokenizers
      transformers
    ]);
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "splash";
    version = "1.5.0";

    src = fetchFromGitHub {
      owner = "incoai";
      repo = "splash";
      tag = finalAttrs.version;
      hash = "sha256-Q6JK3uy3tvptASg0ONYX9IDiUS3L1IR2SH1Txu4mGBQ=";
    };

    # The Metal 4 compiler only ships with Xcode plus its separately downloaded
    # Metal Toolchain component, so the build runs the host's xcrun.
    __noChroot = true;

    # perl for shasum.
    nativeBuildInputs = [perl python3 xcodeWrapper];

    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR"
      unset SDKROOT
      # `xcrun metal` refuses to run unless the Metal Toolchain was downloaded
      # by the same user, which the build user never is; the tools themselves
      # run for anyone.
      make -j"$NIX_BUILD_CORES" all \
        METAL="$(xcrun --find metal)" METALLIB="$(xcrun --find metallib)"
      runHook postBuild
    '';

    # Reuses upstream's release staging so the file lists stay in sync; a
    # release.json makes the launcher treat the install as read-only.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec $out/bin
      python3 -c 'import pathlib, sys; sys.path.insert(0, "dev/tools"); import package; package.stage_runtime(pathlib.Path(sys.argv[1]), sys.argv[2])' \
        $out/libexec ${finalAttrs.version}
      ln -s ${pythonEnv} $out/libexec/python
      cat > $out/bin/splash <<EOF
      #!/bin/sh
      export PYTHONDONTWRITEBYTECODE=1
      exec $out/libexec/python/bin/python3 -u $out/libexec/install/launcher.py "\$@"
      EOF
      chmod +x $out/bin/splash
      runHook postInstall
    '';

    # Stripping would invalidate the linker's ad-hoc code signature.
    dontStrip = true;

    meta = {
      description = "Local inference engine for Apple silicon with DFlash2 speculative decoding";
      homepage = "https://github.com/incoai/splash";
      license = lib.licenses.asl20;
      platforms = ["aarch64-darwin"];
      mainProgram = "splash";
    };
  })
