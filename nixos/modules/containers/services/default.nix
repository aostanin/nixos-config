moduleArgs @ {pkgs, ...}: {
  imports = let
    containerLib = import ./lib.nix moduleArgs;
    args = moduleArgs // {inherit containerLib;};
  in [
    (import ./adguardhome.nix args)
    (import ./authelia.nix args)
    (import ./home-assistant.nix args)
    (import ./invidious.nix args)
    (import ./ir-mqtt-bridge.nix args)
    (import ./frigate.nix args)
    (import ./mealie.nix args)
    (import ./miniflux.nix args)
    (import ./mosquitto.nix args)
    (import ./openwakeword.nix args)
    (import ./piper.nix args)
    (import ./redlib.nix args)
    (import ./searxng.nix args)
    (import ./whisper.nix args)
    (import ./whoami.nix args)
    (import ./uptime-kuma.nix args)
    (import ./valetudopng.nix args)
    (import ./vaultwarden.nix args)
    (import ./zigbee2mqtt.nix args)
  ];
}
