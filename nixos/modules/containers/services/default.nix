moduleArgs @ {pkgs, ...}: {
  imports = let
    containerLib = import ./lib.nix moduleArgs;
    args = moduleArgs // {inherit containerLib;};
  in [
    (import ./adguardhome.nix args)
    (import ./adguardhome-sync.nix args)
    (import ./archivebox.nix args)
    (import ./authelia.nix args)
    (import ./changedetection.nix args)
    (import ./home-assistant.nix args)
    (import ./influxdb.nix args)
    (import ./invidious.nix args)
    (import ./ir-mqtt-bridge.nix args)
    (import ./forgejo.nix args)
    (import ./frigate.nix args)
    (import ./grafana.nix args)
    (import ./guacamole.nix args)
    (import ./jobcan.nix args)
    (import ./mealie.nix args)
    (import ./miniflux.nix args)
    (import ./mosquitto.nix args)
    (import ./netbootxyz.nix args)
    (import ./openwakeword.nix args)
    (import ./piper.nix args)
    (import ./redlib.nix args)
    (import ./searxng.nix args)
    (import ./syncthing.nix args)
    (import ./tasmoadmin.nix args)
    (import ./whisper.nix args)
    (import ./whoami.nix args)
    (import ./unifi.nix args)
    (import ./uptime-kuma.nix args)
    (import ./valetudopng.nix args)
    (import ./vaultwarden.nix args)
    (import ./zigbee2mqtt.nix args)
    (import ./zwift-offline.nix args)
  ];
}
