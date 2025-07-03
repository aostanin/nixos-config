{
  config,
  pkgs,
  inputs,
  secrets,
  lib,
  ...
}: {
  boot.kernelPackages = let
    crossPkgs = import pkgs.path {
      localSystem.system = "x86_64-linux";
      crossSystem.system = "aarch64-linux";
    };
  in
    crossPkgs.linuxKernel.packagesFor (crossPkgs.linux_6_12.override {
      kernelPatches = [
        {
          # Cold boot PCIe/NVMe have stability issues.
          # See: https://forum.banana-pi.org/t/bpi-r3-problem-with-pcie/15152
          #
          # FrankW's first patch added a 100ms sleep, this was rejected upstream.
          # Jianjun posted a patch to the forum for testing, and it appears to me
          # to have accidentally missed a write to the registers between the two
          # sleeps.  This version is modified to include the write, and results
          # in the PCI bridge appearing reliably, but not the NVMe device.
          #
          # Without this patch, the PCI bridge is not present, and rescan does
          # not discover it.  Removing the bridge and then rescanning repeatably
          # gets the NVMe working on cold-boot.
          #name = "PCI: mediatek-gen3: handle PERST after reset";
          #patch = ./linux-mtk-pcie.patch;
          name = "pcie-mediatek-gen3-PERST-for-100ms.patch";
          patch = ./611-pcie-mediatek-gen3-PERST-for-100ms.patch;
        }
        {
          # Prevent crashing due to missing rates in wifi data
          #
          # See: https://forum.banana-pi.org/t/bpi-r3-crash-in-sta-set-sinfo-0xa18/15290
          # https://github.com/openwrt/openwrt/issues/13198
          name = "avoid-crashing-missing-band.patch";
          patch = ./780-avoid-crashing-missing-band.patch;
        }
      ];

      ignoreConfigErrors = true;
      structuredExtraConfig = with lib.kernel; {
        # Disable extremely unlikely features to reduce build storage requirements and time.
        FB = lib.mkForce no;
        DRM = lib.mkForce no;
        SOUND = no;
        INFINIBAND = lib.mkForce no;

        # PCIe
        PCIE_MEDIATEK = yes;
        PCIE_MEDIATEK_GEN3 = yes;
        # SD/eMMC
        MTD_NAND_ECC_MEDIATEK = yes;
        # Net
        BRIDGE = yes;
        HSR = yes;
        NET_DSA = yes;
        NET_DSA_TAG_MTK = yes;
        NET_DSA_MT7530 = yes;
        NET_VENDOR_MEDIATEK = yes;
        PCS_MTK_LYNXI = yes;
        NET_MEDIATEK_SOC_WED = yes;
        NET_MEDIATEK_SOC = yes;
        NET_MEDIATEK_STAR_EMAC = yes;
        MEDIATEK_GE_PHY = yes;
        AIR_EN8811H_PHY = yes;
        # WLAN
        WLAN = yes;
        WLAN_VENDOR_MEDIATEK = yes;
        MT76_CORE = module;
        MT76_LEDS = yes;
        MT76_CONNAC_LIB = module;
        MT7915E = module;
        MT798X_WMAC = yes;
        # Pinctrl
        EINT_MTK = yes;
        PINCTRL_MTK = yes;
        PINCTRL_MT7986 = yes;
        # Thermal
        MTK_THERMAL = yes;
        MTK_SOC_THERMAL = yes;
        MTK_LVTS_THERMAL = yes;
        # Clk
        COMMON_CLK_MEDIATEK = yes;
        COMMON_CLK_MEDIATEK_FHCTL = yes;
        COMMON_CLK_MT7986 = yes;
        COMMON_CLK_MT7986_ETHSYS = yes;
        # other
        MEDIATEK_WATCHDOG = yes;
        REGULATOR_MT6380 = yes;
        # for M.2 USB workaround
        GPIO_SYSFS = yes;
      };
    });
}
