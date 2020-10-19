{ config, pkgs, ... }:
let
  secrets = import ../../secrets;
in
{
  boot.loader.grub = {
    extraEntries = ''
      menuentry "iPXE - Windows 10 Play" {
        chainloader @bootRoot@/ipxe-win10-play.efi
      }

      menuentry "iPXE - netboot.xyz" {
        chainloader @bootRoot@/ipxe-netbootxyz.efi
      }
    '';
    extraFiles = {
      "ipxe-win10-play.efi" = let ipxe = pkgs.ipxe.override {
        embedScript = pkgs.writeText "win10-play.ipxe" ''
          #!ipxe
          ifopen net0
          set net0/ip ${secrets.network.home.hosts.valmar.address}
          set net0/gateway 0.0.0.0
          set net0/netmask 255.255.255.0

          set iscsi-target-host ${secrets.network.home.hosts.elena.address}
          set iscsi-target-iqn iqn.2003-01.org.linux-iscsi.elena.x8664
          set initiator-iqn iqn.1991-05.com.microsoft:desktop-ju4818u

          set keep-san 1

          sanboot iscsi:''${iscsi-target-host}:::0:''${iscsi-target-iqn}:sn.076cc16bd2ea
        '';
      }; in "${ipxe}/ipxe.efi";
      "ipxe-netbootxyz.efi" = let ipxe = pkgs.ipxe.override {
        embedScript = pkgs.writeText "netbootxyz.ipxe" ''
          #!ipxe
          ifopen net0
          dhcp
          chain --autofree https://boot.netboot.xyz/ipxe/netboot.xyz.efi
        '';
      }; in "${ipxe}/ipxe.efi";
    };
  };
}
