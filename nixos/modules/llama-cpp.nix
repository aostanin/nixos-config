{inputs, ...}: {
  # The in-tree module on nixos-25.11 lacks modelsDir/modelsPreset support.
  # Pull the newer module from nixpkgs-unstable instead.
  disabledModules = ["services/misc/llama-cpp.nix"];
  imports = ["${inputs.nixpkgs-unstable}/nixos/modules/services/misc/llama-cpp.nix"];
}
