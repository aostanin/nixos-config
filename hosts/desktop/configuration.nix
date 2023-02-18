{
  config,
  pkgs,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel/cpu-only.nix"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/msmtp
    ../../modules/zerotier
    ../../modules
    ./power-management.nix
  ];

  variables = {
    hasBattery = false;
    hasBacklightControl = false;
    hasDesktop = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # TODO: Move
      efi.efiSysMountPoint = "/boot/efi";
    };
    tmpOnTmpfs = true;
    #extraModulePackages = with config.boot.kernelPackages; [
    #  kvmfr
    #];
    kernelModules = [
      "amdgpu"
    ];
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "intel_pstate=active"
      # For virsh console
      "console=ttyS0,115200"
      "console=tty1"
    ];
  };

  hardware .opengl.extraPackages = with pkgs; [
    amdvlk
    rocm-opencl-icd
  ];

  networking = {
    hostName = "desktop";
    hostId = "203d588e";
    interfaces.enp1s0.useDHCP = true;
  };

  services = {
    qemuGuest.enable = true;

    udev.packages = with pkgs; [
      stlink
    ];

    xserver = {
      videoDrivers = ["amdgpu"];
      deviceSection = ''
        Option "TearFree" "true"
      '';
      xrandrHeads = [
        {
          output = "HDMI-A-0";
          primary = true;
          monitorConfig = ''
            Option "Position" "0 1440"
          '';
        }
        {
          #output = "DVI-D-0";
          output = "DisplayPort-2";
          monitorConfig = ''
            Option "Position" "440 0"
          '';
        }
      ];
    };
  };

  virtualisation = {
    libvirtd.enable = true;

    docker = {
      enable = true;
      liveRestore = false;
      autoPrune = {
        enable = true;
        flags = [
          "--all"
          "--filter \"until=168h\""
        ];
      };
    };
  };
}
