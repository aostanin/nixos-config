{ config, pkgs, ... }:

{
  services.zerotierone = {
    enable = true;
    joinNetworks = [
        "***REMOVED***"
    ];
  };
}