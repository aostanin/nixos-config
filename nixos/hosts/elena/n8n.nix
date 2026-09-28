{secrets, ...}: {
  services.n8n = {
    enable = true;
    environment = {
      N8N_LISTEN_ADDRESS = "127.0.0.1";
      N8N_PROXY_HOPS = 1;
      WEBHOOK_URL = "https://n8n.${secrets.domain}/";
    };
  };

  localModules.ingress.n8n.port = 5678;
}
