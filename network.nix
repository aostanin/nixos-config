let
  stateVersion = import ./state-version.nix;
  sources = import ./nix/sources.nix { };
  nixPath = map (name: name + "=" + sources."${name}".url) (builtins.attrNames sources);
  defineHost = name: host: { config, pkgs, ... }: (import (./. + "/hosts/${name}/configuration.nix") { inherit config pkgs; }) // {
    deployment.targetUser = "root";
    deployment.targetHost = host;
    nix.nixPath = nixPath;
    system.stateVersion = stateVersion;
  };
in
{
  network.description = "Home";

  elena = defineHost "elena" "fc10:bffb:4dde:9437:5f38::1";
  mareg = defineHost "mareg" "fc10:bffb:4d3a:ff38:7529::1";
  roan = defineHost "roan" "fc10:bffb:4d64:3a10:901e::1";
  valmar = defineHost "valmar" "fc10:bffb:4d80:f017:90c0::1";
}
