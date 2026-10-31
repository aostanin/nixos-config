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

  # RTL8127ATF SFP+ support in r8169 needs 7.0+.
  boot.kernelPackages = pkgs.linuxPackages_7_2;
  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel" "nct6687"];
  # For hardware monitoring on the MSI board's Nuvoton NCT6687D.
  # 26.05's snapshot calls strncpy, which 7.x no longer provides.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.nct6687d.overrideAttrs {
      inherit (pkgs.unstable.linuxPackages.nct6687d) src version;
    })
  ];

  # Partition layout, rpool, and fileSystems/swap come from disko-config.nix.
  disko.devices.disk.main.device = "/dev/disk/by-id/nvme-SHPP41-2000GM_ADC8N56931240921A";
  disko.devices.disk.vm.device = "/dev/disk/by-id/nvme-Sabrent_Rocket_4.0_1TB_BE250717022D00135054";
  disko.zfs.enable = true;

  # The iGPU drives the displays; the NVIDIA card is for compute only.
  services.xserver.videoDrivers = ["modesetting" "nvidia"];
  hardware.nvidia = {
    # Required for Blackwell.
    open = true;
    # 26.05's 595.71.05 calls strncpy, which 7.x no longer provides. Unstable's
    # driver definitions, built against this kernel.
    package =
      (config.boot.kernelPackages.callPackage "${inputs.nixpkgs-unstable}/pkgs/os-specific/linux/nvidia-x11" {}).production;
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

  # The LG ultrawide sits on the NanoKVM Pro's loop-out. Once it sleeps, the
  # NanoKVM flaps HPD with an unreadable EDID, so the connector stays
  # disconnected and the screen never wakes. Serve its EDID from firmware and
  # force the connector on. This is the LG's own EDID, read directly from the
  # monitor; the NanoKVM's splitter otherwise serves a mangled merge of it.
  hardware.display = {
    edid.packages = [
      (pkgs.runCommand "edid-lg-ultrawide" {} ''
        mkdir -p $out/lib/firmware/edid
        ${lib.getExe' pkgs.xxd "xxd"} -r -p > $out/lib/firmware/edid/lg-ultrawide.bin <<'EOF'
        00FFFFFFFFFFFF001E6D2E77BBCD0200
        081D010380502278EACA95A6554EA126
        0F50542108007140818081C0A9C0B300
        D1C081000101E77C70A0D0A029503020
        3A00204F3100001A9D6770A0D0A02250
        30203A00204F3100001A000000FD0038
        3D1E5A20000A202020202020000000FC
        004C472048445220575148440A2001A7
        020340F1230907074E01030405101213
        141F5D5E5F6061830100006D030C0010
        00B83C20006001020367D85DC4017880
        03E30F0030E305C000E6060501595256
        9F3D70A0D0A0155030203A00204F3100
        001A7E4800E0A0381F4040403A00204F
        31000018000000FF003930384E544D58
        35443733390A000000000000000000EE
        EOF
      '')
    ];
    outputs."HDMI-A-1" = {
      edid = "lg-ultrawide.bin";
      mode = "e";
    };
  };

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
