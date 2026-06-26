{
  config,
  lib,
  ...
}: let
  cfg = config.localModules.adguardhome;
in {
  options.localModules.adguardhome.enable =
    lib.mkEnableOption "declarative AdGuard Home (native), the filtering upstream behind coredns";

  config = lib.mkIf cfg.enable {
    services.adguardhome = {
      enable = true;
      mutableSettings = false;
      host = "127.0.0.1";
      port = 3000;
      settings = {
        dns = {
          bind_hosts = ["127.0.0.1"];
          port = 5300;
          upstream_dns = [
            "tls://1.1.1.1"
            "tls://8.8.8.8"
            "tls://[2606:4700:4700::1111]"
            "tls://[2001:4860:4860::8888]"
          ];
          bootstrap_dns = ["9.9.9.10" "149.112.112.10" "2620:fe::10" "2620:fe::fe:10"];
          use_private_ptr_resolvers = false;
        };
        filters = [
          {
            enabled = true;
            id = 1;
            name = "AdGuard DNS filter";
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          }
          {
            enabled = true;
            id = 2;
            name = "AdAway Default Blocklist";
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          }
          {
            enabled = true;
            id = 1684188226;
            name = "WindowsSpyBlocker - Hosts spy rules";
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_23.txt";
          }
          {
            enabled = true;
            id = 1684188227;
            name = "Steven Black's List";
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt";
          }
        ];
        user_rules = [
          "@@||email.strava.com^$important"
          "@@||ck.jp.ap.valuecommerce.com^$important"
          "@@||h.accesstrade.net^$important"
          "@@||is.accesstrade.net^$important"
          "@@||s.click.aliexpress.com^$important"
        ];
      };
    };
  };
}
