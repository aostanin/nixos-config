{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lm_sensors
    pciutils
    usbutils

    file
    git
    gnumake
    htop
    ncdu
    neovim
    stow
    tmux
    vim
    wget
    which
  ];
}
