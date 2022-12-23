{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
}:
stdenv.mkDerivation {
  pname = "i915-sriov";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "strongtz";
    repo = "i915-sriov-dkms";
    rev = "a2385b699636d8394e19fb4078f6d3bd63ee6c0f";
    sha256 = "sha256-faGJA6YIO/TjyjMwW4x6zSZ4xUR1rnaQepCsM5XSCR0=";
  };

  setSourceRoot = ''
    export sourceRoot=$(pwd)/source
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  hardeningDisable = ["pic"];

  makeFlags =
    kernel.makeFlags
    ++ [
      "-C"
      "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "M=$(sourceRoot)"
      "KBASE=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
    ];

  buildFlags = [];

  installPhase = ''
    install -v -D -m 644 i915.ko "$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/gpu/drm/i915/i915-sriov.ko"
    xz "$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/gpu/drm/i915/i915-sriov.ko"
  '';
}
