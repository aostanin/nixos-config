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
    rev = "f3442a6f9c5e1b022e9d1f578b61ad371b12bd24";
    sha256 = "sha256-cctTOMZFU88MMeUe1CwhdNChcU430Nm9G2v+LQhnQkI=";
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
