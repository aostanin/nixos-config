{
  config,
  pkgs,
  lib,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
  iface = "enx${lib.replaceStrings [":"] [""] secrets.network.nics.nas.integrated}";
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel/cpu-only.nix"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/msmtp
    ../../modules/zerotier
    ../../modules
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["zfs"];
    zfs = {
      extraPools = ["tank"];
      forceImportAll = true;
      requestEncryptionCredentials = false;
    };
    tmpOnTmpfs = true;
    kernelParams = [
      # For virsh console
      "console=ttyS0,115200"
      "console=tty1"
      "i915.enable_guc=3"
    ];
    kernelPackages = let
      configuredKernel = pkgs.linuxPackages_6_1.kernel.override {
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

  systemd.network.links."11-default" = {
    matchConfig.OriginalName = "*";
    linkConfig.NamePolicy = "mac";
    linkConfig.MACAddressPolicy = "persistent";
  };

  networking = {
    hostName = "nas";
    hostId = "6c3f8459";

    interfaces."${iface}" = {
      macAddress = secrets.network.home.hosts.nas.macAddress;
      ipv4.addresses = [
        {
          address = secrets.network.home.hosts.nas.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = secrets.network.home.defaultGateway;
    nameservers = [secrets.network.home.nameserverPihole];
  };

  services = {
    qemuGuest.enable = true;

    scrutiny.enable = true;

    xserver.videoDrivers = ["intel"];
  };

  virtualisation = {
    docker = {
      enable = true;
      liveRestore = false;
    };
  };

  systemd = {
    timers.update-mam = {
      wantedBy = ["timers.target"];
      partOf = ["update-mam.service"];
      after = ["network-online.target"];
      timerConfig = {
        OnCalendar = "0/2:00";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };

    services.update-mam = {
      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = "/storage/appdata/scripts/mam";
        ExecStart = "/storage/appdata/scripts/mam/update_mam.sh";
      };
    };
  };
}
