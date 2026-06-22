{...}: let
  port = 8081;
in {
  services.meshcentral = {
    enable = true;
    settings = {
      settings = {
        Port = port;
        RedirPort = 0;
        TlsOffload = true;
        mpsport = 0;
      };
      domains."".allowedOrigin = true;
    };
  };

  localModules.ingress.meshcentral.backendUrl = "http://127.0.0.1:${toString port}";
}
