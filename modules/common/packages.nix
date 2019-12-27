{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
    smartmontools
    usbutils

    file
    git
    htop
    ncdu
    neovim
    tmux
    wget
    which

    # TODO: remove after switching to home-manager
    gnumake
    stow
    vim
  ];
}
