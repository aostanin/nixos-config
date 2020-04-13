{ nixPath, stateVersion }:
{
  network.description = "Home";

  elena = { config, pkgs, ... }:
    (import ./hosts/elena/configuration.nix { inherit config pkgs; }) // {
      deployment.targetHost = "fc10:bffb:4dde:9437:5f38::1";
      deployment.hasFastConnection = true;
      nix.nixPath = nixPath;
      system.stateVersion = stateVersion;
    };

  mareg = { config, pkgs, ... }:
    (import ./hosts/mareg/configuration.nix { inherit config pkgs; }) // {
      deployment.targetHost = "fc10:bffb:4d3a:ff38:7529::1";
      deployment.hasFastConnection = true;
      nix.nixPath = nixPath;
      system.stateVersion = stateVersion;
    };

  roan = { config, pkgs, ... }:
    (import ./hosts/roan/configuration.nix { inherit config pkgs; }) // {
      deployment.targetHost = "fc10:bffb:4d64:3a10:901e::1";
      deployment.hasFastConnection = true;
      nix.nixPath = nixPath;
      system.stateVersion = stateVersion;
    };

  valmar = { config, pkgs, ... }:
    (import ./hosts/valmar/configuration.nix { inherit config pkgs; }) // {
      deployment.targetHost = "fc10:bffb:4d80:f017:90c0::1";
      deployment.hasFastConnection = true;
      nix.nixPath = nixPath;
      system.stateVersion = stateVersion;
    };
}
