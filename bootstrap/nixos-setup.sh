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
  users.users.root.openssh.authorizedKeys.keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtPiyHHtDhUJ1jsAP6eUapQrjcyVW6D1EykWDE9e7FDRHg/o63wtpP9WkfvmcGlzHUFPDIyFWwxqKz9O/+M3d/QJ+IPv5Xk33UsHfZNk36BnuDM9G2TmpIKIkKvRG0zhxZOIQnrY3jUl24xdwixeJN2oJj8FAAFbGPSWtyuh8Jnw5tSVo9KPYVfRnwVMMbxVj57OCI3eSsggQoVf1nxiR45EVbKneAUwdVIe0ZrAQVvhVi2iQYDpWWu3J/Yq2tipr91E14HrhrursRCdyisbjy6SeXjz84fIDiMurqs5sQ9qop7RkgWEF8YGmG7De4yqGxxzBv3A2XVvY9aW6lXaKKQ== aostanin@gmail.com"];
  system.stateVersion = "23.11";
}
EOF

nixos-install --no-root-password
