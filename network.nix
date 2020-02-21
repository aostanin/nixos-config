{ nixPath, stateVersion }:
{
    network.description = "Home";

    elena = { config, pkgs, ... }:
    (import ./hosts/elena/configuration.nix { inherit config pkgs; }) // {
      deployment.targetHost = "elena";
      deployment.hasFastConnection = true;
      nix.nixPath = nixPath;
      system.stateVersion = stateVersion;
    };

    mareg = { config, pkgs, ... }:
    (import ./hosts/mareg/configuration.nix { inherit config pkgs; }) // {
      deployment.targetHost = "mareg";
      deployment.hasFastConnection = true;
      nix.nixPath = nixPath;
      system.stateVersion = stateVersion;
    };

    roan = { config, pkgs, ... }:
    (import ./hosts/roan/configuration.nix { inherit config pkgs; }) // {
      deployment.targetHost = "roan";
      deployment.hasFastConnection = true;
      nix.nixPath = nixPath;
      system.stateVersion = stateVersion;
    };

    valmar = { config, pkgs, ... }:
    (import ./hosts/valmar/configuration.nix { inherit config pkgs; }) // {
      deployment.targetHost = "valmar";
      deployment.hasFastConnection = true;
      nix.nixPath = nixPath;
      system.stateVersion = stateVersion;
    };
}
