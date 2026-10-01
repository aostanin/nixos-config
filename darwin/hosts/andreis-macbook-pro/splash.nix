{
  config,
  pkgs,
  ...
}: {
  sops.secrets."splash/api_key" = {};

  localModules.splash = {
    enable = true;
    package = pkgs.splash.override {python3 = pkgs.unstable.python313;};
    model = "ajgazin/Swift-Qwen3.8-27B-Uncensored-Dynamic-MTP-GGUF:UD-Q5_K_M";
    revision = "6a7d8701f966d221cf076b4a4240d875a0ced02d";
    host = "0.0.0.0";
    port = 8085;
    apiKeyFile = config.sops.secrets."splash/api_key".path;
    wakeOnRequest = true;
    allowedHosts = [
      config.networking.hostName
      "${config.networking.hostName}.local"
    ];
    extraFlags = ["--max-context" "256K"];
  };
}
