{
  config,
  lib,
  pkgs,
  ...
}: {
  boot = {
    kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_guc=7"
      "vfio-pci.ids=1912:0014,1b73:1100" # USB
    ];
    kernelPackages = let
      configuredKernel = config.boot.zfs.package.latestCompatibleLinuxPackages.kernel.override {
        structuredExtraConfig = with lib.kernel; {
          # Needed to build i915-sriov. Is there a better way to do this?
          DRM_I915_PXP = yes;
          PMIC_OPREGION = yes;
        };
      };
      i915-sriov = (pkgs.linuxPackagesFor configuredKernel).callPackage ../../packages/i915-sriov {};
    in
      pkgs.linuxPackagesFor (configuredKernel.overrideAttrs (old: {
        passthru = configuredKernel.passthru;
        nativeBuildInputs = old.nativeBuildInputs ++ [i915-sriov];
        postInstall =
          old.postInstall
          # Overwrite the kernel's i915 module with i915-sriov. There has to be a better way to do this, but
          # I couldn't figure out how to overwrite a single module without rebuilding the kernel.
          + ''
            cp ${i915-sriov}/lib/modules/${configuredKernel.modDirVersion}/kernel/drivers/gpu/drm/i915/i915-sriov.ko.xz $out/lib/modules/${configuredKernel.modDirVersion}/kernel/drivers/gpu/drm/i915/i915.ko.xz
          '';
      }));
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="drm", KERNELS=="0000:00:02.0", ATTR{device/sriov_numvfs}="4"
  '';

  services.vfio = let
    amdRX570 = {
      # RX 570
      driver = "amdgpu";
      pciIds = ["1458:22f7" "1458:aaf0"];
      busId = "09:00.0";
    };
    #nvidiaQuadroP400 = {
    #  # Quadro P400
    #  driver = "nvidia";
    #  pciIds = ["10de:1cb3" "10de:0fb9"];
    #  busId = "01:00.0";
    #};
    nvidiaRTX2070Super = {
      # RTX 2070 Super
      driver = "nvidia";
      pciIds = ["10de:1e84" "10de:10f8" "10de:1ad8" "10de:1ad9"];
      busId = "01:00.0";
    };
  in {
    enable = true;
    cpuType = "intel";
    enableLookingGlass = true;
    gpu = nvidiaRTX2070Super;
    vms = let
      isolate8Core = {
        enable = true;
        dropCaches = false;
        compactMemory = false;
        isolateCpus = true;
        allCpus = ["0-11"];
        hostCpus = ["0-3"];
        guestCpus = ["0-1" "4-11"];
      };
    in {
      valmar = {
        useGpu = false;
        enableHibernation = true;
      };
      win10-play = {
        useGpu = true;
        enableHibernation = true;
        isolate = isolate8Core;
      };
      win10-work = {
        useGpu = false;
        enableHibernation = true;
      };
      win10-work-intel = {
        useGpu = false;
        enableHibernation = true;
      };
    };
  };
}
