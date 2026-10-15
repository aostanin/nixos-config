{secrets, ...}: {
  # Paseo's web UI, plus its service proxy for workspace dev servers. The dev
  # container runs on valmar (dev-container.nix); its Traefik route stays here.
  localModules.ingress.paseo = {
    backendUrl = "http://${secrets.network.home.hosts.dev.address}:6767";
    hosts = [
      "paseo.${secrets.domain}"
      "*.paseoapps.${secrets.domain}"
    ];
  };
}
