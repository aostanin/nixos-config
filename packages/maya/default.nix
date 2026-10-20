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
  # nvcc 13.2 miscompiles the IQ*_S grid reads for sm_120, and Maya's quants
  # are IQ2/IQ3: every answer is garbage.
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
      numpy
      pillow
      psutil
      pyyaml
      referencing
      regex
    ]);
in
  cudaPackages.backendStdenv.mkDerivation (finalAttrs: {
    pname = "maya";
    version = "1.1.16";

    src = fetchFromGitHub {
      owner = "mw00";
      repo = "project-maya";
      tag = "v${finalAttrs.version}";
      hash = "sha256-nmh7HDN6rerXMKD8PZfUITZz9vbEzUCxlo5s3nl7KvU=";
    };

    nativeBuildInputs = [
      autoAddDriverRunpath
      cmake
      cudaPackages.cuda_nvcc
      makeWrapper
      ninja
      python3
    ];

    buildInputs = with cudaPackages; [
      cuda_cccl
      cuda_cudart
      cuda_nvtx
      cuda_profiler_api
      libcublas
    ];

    cmakeFlags = [
      (lib.cmakeBool "STRATA_ENABLE_CUDA" true)
      (lib.cmakeBool "STRATA_NATIVE_EXPERTS" true)
      (lib.cmakeBool "STRATA_BUILD_TESTS" false)
      (lib.cmakeBool "STRATA_PORTABLE" true)
      (lib.cmakeFeature "STRATA_GGML_DIR" "${llama-cpp-src}")
      (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaPackages.flags.cmakeCudaArchitecturesString)
    ];

    ninjaFlags = ["maya"];

    # The image encoder is llama.cpp's mtmd with GLM-5.3-Flash's vision tower
    # patched into a copy of the tree.
    postBuild = ''
      cp -r --no-preserve=mode ${llama-cpp-src} llama-vision
      python3 $src/tools/vision/glm5next_patch.py llama-vision
      cmake -S $src/tools/vision -B vision -G Ninja -DCMAKE_BUILD_TYPE=Release \
        -DLLAMA_DIR=$PWD/llama-vision -DSTRATA_VISION_CUDA=ON \
        -DCMAKE_CUDA_ARCHITECTURES="$(sed -n 's/^CMAKE_CUDA_ARCHITECTURES:[A-Z]*=//p' CMakeCache.txt)"
      ninja -C vision -j$NIX_BUILD_CORES maya-vision
    '';

    env.NIX_CFLAGS_COMPILE = lib.optionalString (cpuArch != null) "-march=${cpuArch}";

    # The server finds its web UI, VERSION and tools relative to the source
    # tree; the run config names the engine.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/maya $out/bin
      cp -r $src/{serve,tools,data,VERSION} $out/share/maya/
      install -Dm755 -t $out/share/maya/engine maya vision/bin/maya-vision
      # The server loads libnvidia-ml (web UI telemetry) and libcuda through
      # ctypes. Its updater would git-pull the store path.
      makeWrapper ${python.interpreter} $out/bin/maya-server \
        --prefix LD_LIBRARY_PATH : ${addDriverRunpath.driverLink}/lib \
        --set MAYA_UPDATE_CHECK 0 \
        --add-flags $out/share/maya/serve/server.py
      # Turns the GGUF shards into the engine's pack, once per model.
      makeWrapper ${python.interpreter} $out/bin/maya-pack \
        --set STRATA_GGUF_PY ${llama-cpp-src}/gguf-py \
        --add-flags $out/share/maya/tools/iq_pack.py
      runHook postInstall
    '';

    passthru = {inherit python llama-cpp-src;};

    meta = {
      description = "Runs GLM-5.3-Flash on consumer GPUs, with its experts tiered across VRAM, RAM and SSD";
      homepage = "https://github.com/mw00/project-maya";
      license = lib.licenses.mit;
      mainProgram = "maya-server";
      platforms = ["x86_64-linux"];
    };
  })
