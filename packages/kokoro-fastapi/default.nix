{
  lib,
  fetchFromGitHub,
  fetchurl,
  makeWrapper,
  python3Packages,
  runCommand,
  stdenvNoCC,
}: let
  # misaki's default Japanese G2P needs it, and nixpkgs lacks it.
  mojimoji = python3Packages.buildPythonPackage rec {
    pname = "mojimoji";
    version = "0.0.13";
    pyproject = true;
    src = python3Packages.fetchPypi {
      inherit pname version;
      hash = "sha256-Dm0vuiLMi/Eypb3zqWQpbZKHphjQloGhKGjw/VGOQjA=";
    };
    build-system = with python3Packages; [cython setuptools wheel];
    pythonImportsCheck = ["mojimoji"];
  };

  # The release assets upstream's download_model.py fetches at startup. Copied,
  # not linked: the loader resolves symlinks before looking for config.json
  # beside the weights.
  model = let
    fetchAsset = name: sha256:
      fetchurl {
        url = "https://github.com/remsky/Kokoro-FastAPI/releases/download/v0.1.4/${name}";
        inherit sha256;
      };
  in
    runCommand "kokoro-v1_0" {} ''
      mkdir -p $out/v1_0
      cp ${fetchAsset "kokoro-v1_0.pth" "496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4"} $out/v1_0/kokoro-v1_0.pth
      cp ${fetchAsset "config.json" "5abb01e2403b072bf03d04fde160443e209d7a0dad49a423be15196b9b43c17f"} $out/v1_0/config.json
    '';

  # Only what api/src imports; upstream's pins are for its uv lock.
  python = python3Packages.python.withPackages (ps:
    with ps; [
      aiofiles
      av
      fastapi
      fugashi
      inflect
      jaconv
      kokoro
      loguru
      mojimoji
      numpy
      phonemizer
      psutil
      pydantic
      pydantic-settings
      # misaki's Japanese module imports it whichever G2P it uses.
      pyopenjtalk
      python-dotenv
      python-multipart
      regex
      soundfile
      spacy-models.en_core_web_sm
      torch
      unicode-segmentation-rs
      # unidic-lite bundles its dictionary; nixpkgs' unidic downloads one.
      unidic-lite
      uvicorn
    ]);
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "kokoro-fastapi";
    version = "0.9.0";

    src = fetchFromGitHub {
      owner = "remsky";
      repo = "Kokoro-FastAPI";
      tag = "v${finalAttrs.version}";
      hash = "sha256-BqDWxVeJPEfliJQBVe6tZPzVdcNaZpxIfkjEepM4PdY=";
    };

    nativeBuildInputs = [makeWrapper];

    # Upstream runs from its source tree rather than an installed package.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/kokoro-fastapi
      cp -r api web VERSION $out/share/kokoro-fastapi
      makeWrapper ${python.interpreter} $out/bin/kokoro-fastapi \
        --add-flags "-m uvicorn api.src.main:app" \
        --prefix PYTHONPATH : $out/share/kokoro-fastapi:$out/share/kokoro-fastapi/api \
        --set-default MODEL_DIR ${model} \
        --set-default VOICES_DIR $out/share/kokoro-fastapi/api/src/voices/v1_0
      runHook postInstall
    '';

    passthru = {inherit model python;};

    meta = {
      description = "OpenAI-compatible FastAPI wrapper for the Kokoro-82M TTS model";
      homepage = "https://github.com/remsky/Kokoro-FastAPI";
      license = lib.licenses.asl20;
      mainProgram = "kokoro-fastapi";
    };
  })
