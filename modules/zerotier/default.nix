{
  config,
  pkgs,
  ...
}: let
  secrets = import ../../secrets;
in {
  services.zerotierone = {
    enable = true;
    joinNetworks = [secrets.zerotier.network];
  };
}
