{
  lib,
  addDriverRunpath,
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
  # nvcc 13.2 miscompiles the IQ*_S grid reads for sm_120, in Strata's kernels
  # and in ggml's MMQ ones that strata-poly links: every answer is garbage.
  # https://github.com/Niko1221/Strata/issues/892
  cudaPackages = cudaPackages_13_0;

  # setup.py's LLAMA_CPP_COMMIT: the ggml of the CPU experts and the MMQ kernels.
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
    pname = "polystrata";
    version = "0.1.45-poly.1";

    src = fetchFromGitHub {
      owner = "VecSzn";
      repo = "PolyStrata";
      tag = "v${finalAttrs.version}";
      hash = "sha256-2iocABBMPqerJi7ztn0WvjYwCHWYm/M+SMkrwQH61tw=";
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

    # The Qwen3.8-Flash-Next engine is the strata package.
    ninjaFlags = ["strata-poly"];

    env.NIX_CFLAGS_COMPILE = lib.optionalString (cpuArch != null) "-march=${cpuArch}";

    # The server finds its web UI and data files relative to the source tree,
    # and tells the engines apart by the executable's name.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/polystrata $out/bin
      cp -r $src/{serve,tools,data} $out/share/polystrata/
      install -Dm755 strata-poly $out/share/polystrata/engine/strata-poly
      # The server loads libnvidia-ml (web UI telemetry) and libcuda through ctypes.
      makeWrapper ${python.interpreter} $out/bin/polystrata-server \
        --prefix LD_LIBRARY_PATH : ${addDriverRunpath.driverLink}/lib \
        --add-flags $out/share/polystrata/serve/server.py
      # Writes a model's tokenizer folder, which the run config's `tokenizer` names.
      makeWrapper ${python.interpreter} $out/bin/polystrata-tokenizer \
        --add-flags $out/share/polystrata/tools/strata_tokenizer.py
      runHook postInstall
    '';

    passthru = {inherit python;};

    meta = {
      description = "Strata's engine for other MoE models: Qwen3.6, Ornith 1.5, Gemma 4 and GLM 5.3 Flash";
      homepage = "https://github.com/VecSzn/PolyStrata";
      license = lib.licenses.mit;
      mainProgram = "polystrata-server";
      platforms = ["x86_64-linux"];
    };
  })
