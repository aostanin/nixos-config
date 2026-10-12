{
  config,
  lib,
  secrets,
  ...
}: let
  cfg = config.localModules.thunderbird;
  profile = secrets.user.username;
  nextcloud = "https://nextcloud.${secrets.domain}/remote.php/dav/calendars/${secrets.user.username}";

  emailAccount = address: {
    inherit address;
    realName = secrets.user.fullName;
    userName = address;
    flavor = "gmail.com";
    primary = address == lib.head secrets.thunderbird.emailAccounts;
    thunderbird.enable = true;
  };

  calendar = {
    path,
    color,
    primary ? false,
    readOnly ? false,
  }: {
    inherit primary;
    remote = {
      type = "caldav";
      url = "${nextcloud}/${path}/";
      userName = secrets.user.username;
    };
    thunderbird = {
      enable = true;
      inherit color readOnly;
    };
  };
in {
  options.localModules.thunderbird = {
    enable = lib.mkEnableOption "thunderbird";
  };

  config = lib.mkIf cfg.enable {
    accounts.email.accounts = lib.genAttrs secrets.thunderbird.emailAccounts emailAccount;

    accounts.calendar.accounts = {
      Personal = calendar {
        path = "personal";
        color = "#00679e";
      };
      home = calendar {
        path = "home";
        color = "#ffcc33";
        primary = true;
      };
      work = calendar {
        path = "work";
        color = "#663366";
      };
      "Contact birthdays" = calendar {
        path = "contact_birthdays";
        color = "#e9d859";
        readOnly = true;
      };
      Tasks = calendar {
        path = "tasks";
        color = "#00679e";
      };
    };

    programs.thunderbird = {
      enable = true;
      profiles.${profile} = {
        isDefault = true;
        accountsOrder = secrets.thunderbird.emailAccounts ++ ["account_smart"];
        calendarAccountsOrder = ["Personal" "home" "work" "Contact birthdays" "Tasks"];
        settings = {
          # Unified Folders' hidden account. Left to Thunderbird it gets a
          # generated key that drops out of the pinned account list on the next
          # start, and a fresh one is created every launch.
          "mail.account.account_smart.server" = "server_smart";
          "mail.server.server_smart.directory-rel" = "[ProfD]Mail/smart mailboxes";
          "mail.server.server_smart.hidden" = true;
          "mail.server.server_smart.hostname" = "smart mailboxes";
          "mail.server.server_smart.type" = "none";
          "mail.server.server_smart.userName" = "nobody";

          "mail.inappnotifications.donation_enabled" = false;
          "mail.pane_config.dynamic" = 1;
          "mail.purge.ask" = false;
          "mail.shell.checkDefaultClient" = false;
          "mail.uidensity" = 0;
          "mailnews.start_page.enabled" = false;
        };
      };
    };
  };
}
