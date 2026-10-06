let
  port = 5006;
in {
  services.actual = {
    enable = true;
    settings = {
      hostname = "127.0.0.1";
      inherit port;
    };
  };

  localModules.ingress.actual.port = port;
}
