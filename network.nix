let
  stateVersion = import ./state-version.nix;
  nixPath = import ./nix-path.nix;
  secrets = import ./secrets;
  defineHost = name: host: { config, pkgs, ... }: (import (./. + "/hosts/${name}/configuration.nix") { inherit config pkgs; }) // {
    deployment.targetUser = "root";
    deployment.targetHost = host;
    nix.nixPath = nixPath;
    system.stateVersion = stateVersion;
  };
in
with secrets.network.zerotier; {
  network.description = "Home";

  elena = defineHost "elena" hosts.elena.address;
  mareg = defineHost "mareg" hosts.mareg.address;
  roan = defineHost "roan" hosts.roan.address;
  valmar = defineHost "valmar" hosts.valmar.address;
}
