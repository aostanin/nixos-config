{ config, pkgs, ... }:

{
  nixpkgs.config.packageOverrides = pkgs: with pkgs; {
	# Fix missing evdev symlinks https://github.com/systemd/systemd/issues/13518
    systemd = pkgs.systemd.overrideAttrs(attrs: {
      patches = [
        ./13500.diff # Fix udev https://github.com/systemd/systemd/pull/13500
        ./13519.diff # Fix udev https://github.com/systemd/systemd/pull/13519
      ];
    });
  };
}
