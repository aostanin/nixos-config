{
  config,
  pkgs,
  secrets,
  ...
}: {
  services.zerotierone = {
    enable = true;
    joinNetworks = [secrets.zerotier.network];
  };
}
