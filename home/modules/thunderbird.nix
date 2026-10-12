{
  pkgs,
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

  # Window state lives in xulstore.json, which Thunderbird rewrites itself, so
  # it's applied on every start from the wrapper's autoconfig script instead.
  # "-moz-missing\n" is xulstore's marker for a removed attribute.
  xulStore."chrome://messenger/content/messenger.xhtml" = {
    folderTree.mode = "smart";
    folderPaneLocalFolders.hidden = "true";
    threadPaneHeader.hidden = "true";
    toolbar-menubar.autohide = "-moz-missing\n";
    todo-tab-panel.collapsedinmodes = "mail,task,chat,calendarEvent,calendarTask";
    unifinder-todo-tree.filterValue = "throughcurrent";
    view-box.selectedIndex = "1";
  };
  xulStoreJs = lib.concatLines (lib.flatten (lib.mapAttrsToList (doc: elements:
    lib.mapAttrsToList (id: attrs:
      lib.mapAttrsToList (attr: value: "Services.xulStore.setValue(${lib.concatMapStringsSep ", " builtins.toJSON [doc id attr value]});")
      attrs)
    elements)
  xulStore));
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
      package = (pkgs.thunderbird.override {extraPrefs = xulStoreJs;}).overrideAttrs (old:
        lib.optionalAttrs pkgs.stdenv.isDarwin {
          # nixpkgs' wrapper writes autoconfig.js where Firefox reads it on
          # macOS; Thunderbird only reads defaults/pref, so mozilla.cfg never runs.
          buildCommand =
            old.buildCommand
            + ''
              resources=$out/Applications/Thunderbird.app/Contents/Resources
              mkdir -p $resources/defaults/pref
              cp $resources/browser/defaults/preferences/autoconfig.js $resources/defaults/pref/
            '';
        });
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
