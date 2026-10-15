{
  config,
  pkgs,
  ...
}: {
  localModules.whisper-cpp = {
    enable = true;
    package = pkgs.unstable.pkgsForCudaArch.sm_75.whisper-cpp;
    port = 8086;
  };

  localModules.ingress.whisper-cpp.port = config.localModules.whisper-cpp.port;
}
