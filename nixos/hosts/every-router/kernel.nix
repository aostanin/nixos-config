{
  pkgs,
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
          name = "pcie-mediatek-gen3-PERST-for-100ms.patch";
          patch = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/openwrt/openwrt/166d9d5ea2e70891d2cf757ee96de823aeec8c53/target/linux/mediatek/patches-6.12/611-pcie-mediatek-gen3-PERST-for-100ms.patch";
            hash = "sha256-IK1JEOvjabjfRMfQyXcx5evx22UIVITqLXsSl0SKfaQ=";
          };
        }
        {
          name = "avoid-crashing-missing-band.patch";
          patch = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/openwrt/openwrt/166d9d5ea2e70891d2cf757ee96de823aeec8c53/package/kernel/mac80211/patches/subsys/230-avoid-crashing-missing-band.patch";
            hash = "sha256-W14qBOetBSFteVlZP6qZfVXixB3c6fiTOqHjxakmGF4=";
          };
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
