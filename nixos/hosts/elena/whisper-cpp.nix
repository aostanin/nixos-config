{pkgs, ...}: {
  # Run by llama-swap (llama-swap.nix), which reads these settings.
  localModules.whisper-cpp = {
    enable = false;
    package = pkgs.unstable.pkgsForCudaArch.sm_120.whisper-cpp;
    port = 8086;
  };
}
