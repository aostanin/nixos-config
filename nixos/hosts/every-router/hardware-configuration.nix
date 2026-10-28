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
    # The DTS only sets pull-ups on the M.2 Key-B control pins. SPI1_CS
    # (ngff-coex) is left in its SPI function, which makes the modem's USB
    # enumeration unreliable; hogging it switches it to a GPIO input.
    {
      name = "bpi-r3-mini-ngff-coex";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
            compatible = "bananapi,bpi-r3mini";

            fragment@0 {
                target-path = "/soc/pinctrl@1001f000";
                __overlay__ {
                    ngff-coex-hog {
                        gpio-hog;
                        gpios = <32 0>;
                        input;
                        line-name = "ngff-coex";
                    };
                };
            };
        };
      '';
    }
  ];

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
