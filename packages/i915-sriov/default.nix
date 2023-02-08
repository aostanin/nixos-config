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
    rev = "9996e5c11aad87acaea9060a539084f9a5e90952";
    sha256 = "sha256-TlpaULil4jPX2KPDfw17OUc6mXU+LMVzoO3sj+AjZls=";
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
