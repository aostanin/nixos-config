#!/bin/sh

DISK=$1

parted --script --align optimal $DISK -- \
  mklabel gpt \
  mkpart primary 512MB -17180MB \
  mkpart primary linux-swap -17180MB 100% \
  mkpart ESP fat32 1MB 512MB \
  set 3 esp on

mkswap -L swap $DISK-part2
mkfs.fat -F 32 -n boot $DISK-part3

zpool create -f \
  -o ashift=12 \
  -o autoexpand=on \
  -O canmount=off \
  -O mountpoint=none \
  -O sync=disabled \
  -O atime=off \
  -O compression=zstd \
  -O normalization=formD \
  -O dnodesize=auto \
  -O xattr=sa \
  -O acltype=posixacl \
  -R /mnt \
  rpool $DISK-part1

zfs create -o canmount=off rpool/root
zfs create -o mountpoint=/ rpool/root/nixos
zfs create -o mountpoint=/nix rpool/root/nix
zfs create -o mountpoint=/home rpool/home

mkdir /mnt/boot
mount $DISK-part3 /mnt/boot

# appdata
zfs create -o canmount=off -o mountpoint=/storage/appdata rpool/appdata
zfs create rpool/appdata/docker
zfs create -o mountpoint=/var/lib/libvirt rpool/appdata/libvirt

# virtualization
zfs create -o canmount=off rpool/virtualization
zfs create -o mountpoint=/var/lib/docker rpool/virtualization/docker
zfs create -o canmount=off -o mountpoint=/var/lib/libvirt/images -o recordsize=64K rpool/virtualization/images
zfs create rpool/virtualization/images/isos

nixos-generate-config --root /mnt

cat << EOF > /mnt/etc/nixos/configuration.nix
{ config, lib, pkgs, ... }:
{
  imports = [./hardware-configuration.nix];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostId = "$(head -c 8 /etc/machine-id)";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBKi5mFDoyYSeNmjBZk2pU7BAmA3tUyCxV0Ix7/pWzyq aostanin@gmail.com"];
  system.stateVersion = "23.11";
}
EOF

nixos-install --no-root-password
