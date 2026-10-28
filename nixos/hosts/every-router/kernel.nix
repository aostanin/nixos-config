{
  pkgs,
  lib,
  ...
}: let
  # Other SoC families, and driver families with no hardware on this board.
  # The only PCIe slot holds the NVMe, so no add-in NICs or wifi cards.
  disabled =
    map (s: "ARCH_${s}") [
      "ACTIONS"
      "AIROHA"
      "SUNXI"
      "ALPINE"
      "APPLE"
      "ARTPEC"
      "AXIADO"
      "BCM"
      "BCM2835"
      "BCMBCA"
      "BRCMSTB"
      "BERLIN"
      "BLAIZE"
      "CIX"
      "EXYNOS"
      "K3"
      "LG1K"
      "HISI"
      "KEEMBAY"
      "MESON"
      "MICROCHIP"
      "SPARX5"
      "MVEBU"
      "NXP"
      "LAYERSCAPE"
      "MXC"
      "S32"
      "MA35"
      "NPCM"
      "QCOM"
      "REALTEK"
      "RENESAS"
      "ROCKCHIP"
      "SEATTLE"
      "INTEL_SOCFPGA"
      "SOPHGO"
      "STM32"
      "SYNQUACER"
      "TEGRA"
      "TESLA_FSD"
      "SPRD"
      "THUNDER"
      "THUNDER2"
      "UNIPHIER"
      "VEXPRESS"
      "VISCONTI"
      "XGENE"
      "ZYNQMP"
    ]
    ++ map (s: "NET_VENDOR_${s}") [
      "3COM"
      "ACTIONS"
      "ADAPTEC"
      "AGERE"
      "ALACRITECH"
      "ALLWINNER"
      "ALTEON"
      "AMAZON"
      "AMD"
      "AQUANTIA"
      "ARC"
      "ASIX"
      "ATHEROS"
      "BROADCOM"
      "CADENCE"
      "CAVIUM"
      "CHELSIO"
      "CISCO"
      "CORTINA"
      "DAVICOM"
      "DEC"
      "DLINK"
      "EMULEX"
      "ENGLEDER"
      "EZCHIP"
      "FREESCALE"
      "FUJITSU"
      "FUNGIBLE"
      "GOOGLE"
      "HISILICON"
      "HUAWEI"
      "I825XX"
      "INTEL"
      "ADI"
      "LITEX"
      "MARVELL"
      "MELLANOX"
      "META"
      "MICREL"
      "MICROCHIP"
      "MICROSEMI"
      "MICROSOFT"
      "MYRI"
      "NI"
      "NATSEMI"
      "NETERION"
      "NETRONOME"
      "8390"
      "NVIDIA"
      "OKI"
      "PACKET_ENGINES"
      "PENSANDO"
      "QLOGIC"
      "BROCADE"
      "QUALCOMM"
      "RDC"
      "REALTEK"
      "RENESAS"
      "ROCKER"
      "SAMSUNG"
      "SEEQ"
      "SILAN"
      "SIS"
      "SOLARFLARE"
      "SMSC"
      "SOCIONEXT"
      "STMICRO"
      "SUN"
      "SYNOPSYS"
      "TEHUTI"
      "TI"
      "VERTEXCOM"
      "VIA"
      "WANGXUN"
      "WIZNET"
      "XILINX"
      "XIRCOM"
    ]
    ++ map (s: "WLAN_VENDOR_${s}") [
      "ADMTEK"
      "ATH"
      "ATMEL"
      "BROADCOM"
      "INTEL"
      "INTERSIL"
      "MARVELL"
      "MICROCHIP"
      "PURELIFI"
      "RALINK"
      "REALTEK"
      "RSI"
      "SILABS"
      "ST"
      "TI"
      "ZYDAS"
      "QUANTENNA"
    ]
    ++ [
      "MEDIA_SUPPORT"
      "ATA"
      "SCSI_LOWLEVEL"
      "IIO"
      "STAGING"
      "INPUT_TOUCHSCREEN"
      "INPUT_JOYSTICK"
      "INPUT_TABLET"
      "KVM"
      "XEN"
      "USB_GADGET"
      "REMOTEPROC"
      "RPMSG"
      "FPGA"
      "ISDN"
      "HAMRADIO"
      "CHROME_PLATFORMS"
      "COMEDI"
    ];
in {
  # Since 6.14 pwm-fan no longer probes to MAX_PWM, which is off on this
  # active-low header (ecf1cf1c58c1).
  boot.kernelPackages = pkgs.linuxKernel.packagesFor (pkgs.linux_6_18.override {
    kernelPatches = [
      {
        name = "avoid-crashing-missing-band.patch";
        patch = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/openwrt/openwrt/bf44cb5fb0f510b89e7a651e650dbf71062441d9/package/kernel/mac80211/patches/subsys/230-avoid-crashing-missing-band.patch";
          hash = "sha256-b5HFURwMnxrfT4BCG06D7co0Q2xD/pldJ7flAXBcPeg=";
        };
      }
      {
        # This TF-A blocks direct TRNG access, so without the SMCC path the
        # crng takes minutes to seed and sops-install-secrets blocks in the
        # initrd. Upstream in 7.2.
        name = "hwrng-mtk-add-support-for-hw-access-via-SMCC.patch";
        patch = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/openwrt/openwrt/2129465f980c8bf9614aee322d20c04374378eb1/target/linux/mediatek/patches-6.18/320-hwrng-mtk-add-support-for-hw-access-via-SMCC.patch";
          hash = "sha256-zu4tDICHN8biq0PY19A1UWEwFZY0yUHt52s8lIDiNK8=";
        };
      }
    ];

    ignoreConfigErrors = true;
    structuredExtraConfig = with lib.kernel;
      {
        # Disable extremely unlikely features to reduce build storage requirements and time.
        FB = lib.mkForce no;
        DRM = lib.mkForce no;
        SOUND = no;
        INFINIBAND = lib.mkForce no;

        # PCIe
        PCIE_MEDIATEK_GEN3 = yes;
        # SD/eMMC
        MTD_NAND_ECC_MEDIATEK = yes;
        # Net
        BRIDGE = yes;
        # No switch on this board, and 7.3's NET_DSA depends on HSR, which
        # Kconfig asks about later, so NET_DSA can't be built in.
        NET_DSA = lib.mkForce no;
        NET_VENDOR_MEDIATEK = yes;
        PCS_MTK_LYNXI = yes;
        NET_MEDIATEK_SOC_WED = yes;
        NET_MEDIATEK_SOC = yes;
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
        COMMON_CLK_MT7986 = yes;
        COMMON_CLK_MT7986_ETHSYS = yes;
        # other
        MEDIATEK_WATCHDOG = yes;
      }
      // lib.genAttrs disabled (_: lib.mkForce lib.kernel.no);
  });

  # btrfs forced the root read-only on an in-RAM free-space-tree corruption
  # (write-time tree checker; device stats clean, so nothing reached the disk).
  # This drive is DRAM-less and DMAs into 61 MiB of host memory, and MT7986 has
  # no IOMMU, so HMB is the one thing that can scribble kernel pages out of
  # band. If it recurs without HMB, suspect the DDR.
  boot.kernelParams = ["nvme.max_host_mem_size_mb=0"];

  # pcie_phy_sel is left running by u-boot but no node references it, so
  # clk_disable_unused turns it off. Since 6.18 the async PCIe probe is still
  # bringing up the link when that happens, and the NVMe never appears. List it
  # with the controller's own clocks (IDs from dt-bindings/clock/mt7986-clk.h).
  hardware.deviceTree.overlays = [
    {
      name = "bpi-r3-mini-pcie-phy-clk";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
            compatible = "bananapi,bpi-r3mini";

            fragment@0 {
                target-path = "/soc/pcie@11280000";
                __overlay__ {
                    clocks = <&infracfg 52>, <&infracfg 51>, <&infracfg 53>,
                             <&infracfg 54>, <&topckgen 52>;
                    clock-names = "pl_250m", "tl_26m", "peri_26m", "top_133m",
                                  "phy_26m";
                };
            };
        };
      '';
    }
  ];
}
