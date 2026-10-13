{
  lib,
  autoAddDriverRunpath,
  cmake,
  cudaPackages_13_0,
  fetchFromGitHub,
  makeWrapper,
  ninja,
  python3,
  # A -march target such as "raptorlake". Null builds upstream's portable AVX2
  # baseline; upstream's default, -march=native, would depend on the builder.
  cpuArch ? null,
}: let
  # nvcc 13.2 miscompiles the IQ*_S kernels for sm_120: every answer is garbage.
  # https://github.com/Niko1221/Strata/issues/892
  cudaPackages = cudaPackages_13_0;

  # The ggml that Strata's CPU experts build against: setup.py's LLAMA_CPP_COMMIT.
  llama-cpp-src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "3cf03257f219afbe7334045ff7c6a06ac68c627d";
    hash = "sha256-SRGoXa+4ACBCB3eaG9XFYhMN1i0FyPEy9Rrer+dFGYI=";
  };

  python = python3.withPackages (ps:
    with ps; [
      jinja2
      jsonschema
      pillow
      psutil
      referencing
      regex
    ]);
in
  cudaPackages.backendStdenv.mkDerivation (finalAttrs: {
    pname = "strata";
    version = "0.1.41";

    # Upstream rewrites history, so pin the tag's commit rather than the tag.
    src = fetchFromGitHub {
      owner = "Niko1221";
      repo = "Strata";
      rev = "fb58e0dbc8399662c0e47c76578c6e878b14f6cf";
      hash = "sha256-WhoIwg8GgeG3jAXYLSjNoZyN3RZ3T3JhgJX57fM80eE=";
    };

    nativeBuildInputs = [
      autoAddDriverRunpath
      cmake
      cudaPackages.cuda_nvcc
      makeWrapper
      ninja
    ];

    buildInputs = with cudaPackages; [
      cuda_cccl
      cuda_cudart
      libcublas
    ];

    cmakeFlags = [
      (lib.cmakeBool "STRATA_ENABLE_CUDA" true)
      (lib.cmakeBool "STRATA_BUILD_TESTS" false)
      (lib.cmakeBool "STRATA_PORTABLE" true)
      (lib.cmakeFeature "STRATA_GGML_DIR" "${llama-cpp-src}")
      (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaPackages.flags.cmakeCudaArchitecturesString)
    ];

    ninjaFlags = ["strata"];

    env.NIX_CFLAGS_COMPILE = lib.optionalString (cpuArch != null) "-march=${cpuArch}";

    # The server finds its web UI, tokenizer helpers and data files relative to
    # the source tree, and the engine under engine/ beside them.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/strata $out/bin
      cp -r $src/{serve,tools,data} $out/share/strata/
      install -Dm755 strata $out/share/strata/engine/strata
      makeWrapper ${python.interpreter} $out/bin/strata-server \
        --add-flags $out/share/strata/serve/server.py
      runHook postInstall
    '';

    passthru = {inherit python;};

    meta = {
      description = "Runs Qwen3.8-Flash-Next on a consumer GPU, with its experts on the CPU";
      homepage = "https://github.com/Niko1221/Strata";
      license = lib.licenses.mit;
      mainProgram = "strata-server";
      platforms = ["x86_64-linux"];
    };
  })
