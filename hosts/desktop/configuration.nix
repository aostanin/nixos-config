{
  config,
  pkgs,
  hardwareModulesPath,
  ...
}: let
  secrets = import ../../secrets;
in {
  imports = [
    "${hardwareModulesPath}/common/cpu/intel"
    "${hardwareModulesPath}/common/pc/ssd"
    ./hardware-configuration.nix
    ../../modules/variables
    ../../modules/common
    ../../modules/desktop
    ../../modules/msmtp
    ../../modules/zerotier
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
    kernelParams = [
      # For virsh console
      "console=ttyS0,115200"
      "console=tty1"
    ];
  };

  networking = {
    hostName = "desktop";
    hostId = "662573da";
    interfaces.enp1s0.useDHCP = true;
  };

  powerManagement.powertop.enable = true;

  services = {
    qemuGuest.enable = true;

    xserver = {
      videoDrivers = ["nvidia"];
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
