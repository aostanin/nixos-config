{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    "${inputs.nixos-hardware}/common/cpu/intel"
    ./disko-config.nix
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel" "nct6687"];
  # For hardware monitoring on the MSI board's Nuvoton NCT6687D.
  boot.extraModulePackages = [config.boot.kernelPackages.nct6687d];

  # Partition layout, rpool, and fileSystems/swap come from disko-config.nix.
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-SHPP41-2000GM_ADC8N56931240921A";
  disko.devices.disk.vm.device = "/dev/disk/by-id/nvme-Sabrent_Rocket_4.0_1TB_BE250717022D00135054";
  disko.zfs.enable = true;

  # The iGPU drives the displays; the NVIDIA card is for compute only.
  services.xserver.videoDrivers = ["modesetting" "nvidia"];
  hardware.nvidia = {
    # Required for Blackwell; Turing works with either.
    open = true;
    modesetting.enable = true;
    nvidiaPersistenced = true;
    powerManagement.enable = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Pin EGL to mesa: the NVIDIA card is for compute and VFIO passthrough, and its
  # glvnd vendor file would otherwise be a candidate for the compositor.
  environment.sessionVariables.__EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";

  # WLR_DRM_DEVICES is colon-separated, so it can't take a /dev/dri/by-path name.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", DRIVERS=="i915", SYMLINK+="dri/igpu"
  '';

  # Keep the greeter's wlroots compositor off the NVIDIA card: it otherwise opens
  # it for DRM and, through libglvnd, NVIDIA's EGL.
  services.greetd.settings.default_session.command = let
    cfg = config.services.displayManager.noctalia-greeter;
  in
    lib.concatStringsSep " " [
      (lib.getExe' pkgs.coreutils "env")
      "WLR_DRM_DEVICES=/dev/dri/igpu"
      "__EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"
      "XDG_DATA_DIRS=${config.services.displayManager.sessionData.desktops}/share"
      "${cfg.package}/bin/noctalia-greeter-session -- ${cfg.greeter-args}"
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
