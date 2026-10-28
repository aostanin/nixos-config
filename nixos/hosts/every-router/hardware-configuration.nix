{
  config,
  pkgs,
  ...
}: let
  # OpenWrt's board DTS carries the MT7976 wifi calibration data inline; the
  # upstream DTS has none and the radios don't come up without it.
  openwrtDts = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/openwrt/openwrt/0883bb7d311d22a5cd92454bf1d6129c6857c737/target/linux/mediatek/dts/mt7986a-bananapi-bpi-r3-mini.dts";
    hash = "sha256-IuhjlAuIu+d+aRu+Kfb16vrk+IrISZjR1gS1OjM46NI=";
  };
  wifiEepromOverlay = pkgs.runCommand "bpi-r3-mini-wifi-eeprom.dts" {} ''
    {
      printf '/dts-v1/;\n/plugin/;\n\n/ {\n  compatible = "bananapi,bpi-r3mini";\n\n  fragment@0 {\n    target-path = "/soc/wifi@18000000";\n    __overlay__ {\n'
      sed -n '/mediatek,eeprom-data = </,/>;/p' ${openwrtDts}
      printf '    };\n  };\n};\n'
    } > $out
    grep -q 'eeprom-data' $out
  '';
in {
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.initrd.compressor = "gzip";
  boot.kernelParams = ["console=ttyS0,115200"];

  boot.initrd.includeDefaultModules = false;
  boot.initrd.kernelModules = ["mii" "rfkill" "cfg80211" "mt7915e"];
  boot.initrd.availableKernelModules = ["mmc_block" "nvme"];
  boot.initrd.systemd.tpm2.enable = false;

  hardware.enableRedistributableFirmware = true;
  hardware.wirelessRegulatoryDatabase = true;
  # EN8811H PHYs load their firmware before the root is mounted.
  boot.initrd.extraFirmwarePaths = [
    "airoha/EthMD32.dm.bin"
    "airoha/EthMD32.DSP.bin"
  ];

  hardware.deviceTree.filter = "mt7986a-bananapi-bpi-r3-mini.dtb";
  hardware.deviceTree.overlays = [
    {
      name = "bpi-r3-mini-wifi-eeprom";
      dtsFile = wifiEepromOverlay;
    }
    {
      name = "bpi-r3-emmc";
      dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/mediatek/mt7986a-bananapi-bpi-r3-emmc.dtbo";
    }
  ];

  # Fix unreliable M.2 USB device detection
  boot.initrd.systemd.services.bpir3-usb-fixup = {
    description = "Fix unreliable M.2 USB device detection";
    wantedBy = ["initrd.target"];
    before = ["sysroot.mount"];
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    script = ''
      echo 544 > /sys/class/gpio/export
    '';
  };

  zramSwap.enable = true;
  nix.settings.auto-optimise-store = true;

  fileSystems = let
    btrfsDevice = "/dev/disk/by-uuid/2b18a0c0-3e90-4194-bcee-c94a3bbb7800";
  in {
    "/boot" = {
      device = "/dev/disk/by-uuid/0b5e3376-c7e9-4284-9514-9c3b51244f19";
      fsType = "ext4";
    };
    "/" = {
      device = btrfsDevice;
      fsType = "btrfs";
      options = ["compress=zstd" "subvol=/@"];
    };
    "/nix" = {
      device = btrfsDevice;
      fsType = "btrfs";
      options = ["compress=zstd" "subvol=/@nix" "noatime"];
    };
    "/home" = {
      device = btrfsDevice;
      fsType = "btrfs";
      options = ["compress=zstd" "subvol=/@home"];
    };
    "/btr_pool" = {
      device = btrfsDevice;
      fsType = "btrfs";
      options = ["subvolid=5" "noatime"];
    };
  };
}
