{
  pkgs,
  config,
  lib,
  theme,
  ...
}: let
  cfg = config.localModules.niri;
  palette = theme.palettes.gruvboxDark;

  foot = lib.getExe pkgs.foot;

  # niri appends a disconnected monitor's workspaces rather than re-sorting, so
  # undocking leaves them grouped by their old output (upstream discussion #2965).
  # Goes over the IPC socket rather than `niri msg`: the CLI parses a numeric
  # --reference as an index, so workspaces named "1".."9" are unreachable by name.
  sortWorkspaces = pkgs.writers.writePython3Bin "niri-sort-workspaces" {} ''
    import json
    import os
    import socket
    import sys


    def connect():
        sock = socket.socket(socket.AF_UNIX)
        sock.connect(os.environ["NIRI_SOCKET"])
        return sock


    def request(payload):
        with connect() as sock:
            sock.sendall((json.dumps(payload) + "\n").encode())
            with sock.makefile() as stream:
                return json.loads(stream.readline())["Ok"]


    def moves_for(workspaces):
        by_output = {}
        for workspace in workspaces:
            if workspace["name"] is not None:
                by_output.setdefault(workspace["output"], []).append(workspace)

        moves = []
        for group in by_output.values():
            ordered = sorted(group, key=lambda w: w["name"])
            for index, workspace in enumerate(ordered, 1):
                if workspace["idx"] != index:
                    moves.append((index, workspace["name"]))
        return moves


    def apply(workspaces):
        for index, name in moves_for(workspaces):
            request({"Action": {"MoveWorkspaceToIndex": {
                "index": index,
                "reference": {"Name": name},
            }}})


    if "--watch" not in sys.argv:
        apply(request("Workspaces")["Workspaces"])
        sys.exit()

    # niri stops reading requests on a socket once it streams events, so the
    # moves above go out on their own short-lived connections.
    with connect() as events:
        events.sendall(b'"EventStream"\n')
        with events.makefile() as stream:
            stream.readline()
            for line in stream:
                changed = json.loads(line).get("WorkspacesChanged")
                if changed is not None:
                    apply(changed["workspaces"])
  '';
  msg = args: ''spawn "${lib.getExe config.programs.noctalia.package}" "msg" ${lib.concatMapStringsSep " " (a: "\"${a}\"") args}'';

  noctalia = {
    volumeUp = msg ["volume-up"];
    volumeDown = msg ["volume-down"];
    mute = msg ["volume-mute"];
    micMute = msg ["mic-mute"];
    brightnessUp = msg ["brightness-up"];
    brightnessDown = msg ["brightness-down"];
    notifications = msg ["panel-toggle" "control-center" "notifications"];
    launcher = msg ["panel-toggle" "launcher"];
    lock = msg ["session" "lock"];
    mediaToggle = msg ["media" "toggle"];
    mediaStop = msg ["media" "stop"];
    mediaPrev = msg ["media" "previous"];
    mediaNext = msg ["media" "next"];
    screenshotRegion = msg ["screenshot-region"];
    screenshotScreen = msg ["screenshot-fullscreen"];
    screenshotAnnotate = msg ["screenshot-annotate"];
    calculator = msg ["panel-toggle" "launcher" "/calc "];
    emoji = msg ["panel-toggle" "launcher" "/emo "];
  };

  extraDebug =
    lib.concatMapStrings (line: "\n    ${line}")
    (lib.filter (line: line != "") (lib.splitString "\n" cfg.extraDebug));

  directional = prefix: actions:
    lib.concatStringsSep "\n"
    (lib.concatLists (lib.zipListsWith (keys: action:
        map (key: "    ${prefix}${key} { ${action}; }") keys) [
        ["Left" "H"]
        ["Down" "J"]
        ["Up" "K"]
        ["Right" "L"]
      ]
      actions));

  workspaceBinds =
    lib.concatStringsSep "\n"
    (lib.concatMap (n: [
        "    Mod+${toString n} { focus-workspace \"${toString n}\"; }"
        "    Mod+Shift+${toString n} { move-column-to-workspace \"${toString n}\"; }"
      ])
      (lib.range 1 9));

  workspaces = lib.concatStringsSep "\n" (map (
      n: let
        name = toString n;
        output = cfg.workspaceOutputs.${name} or null;
      in
        if output == null
        then ''workspace "${name}"''
        else ''
          workspace "${name}" {
              open-on-output "${output}"
          }''
    )
    (lib.range 1 9));

  configText = ''
        input {
            keyboard {
                xkb {
                    layout "jp"
                    options "ctrl:nocaps,shift:both_capslock"
                }
            }

            touchpad {
                click-method "clickfinger"
                natural-scroll
            }

            warp-mouse-to-focus
        }

        layout {
            gaps 4
            center-focused-column "never"

            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
            }

            default-column-width { proportion 0.5; }

            focus-ring {
                width 2
                active-color "${palette.primary}"
                inactive-color "${palette.surface}"
                urgent-color "${palette.error}"
            }

            border {
                off
            }

            tab-indicator {
                place-within-column
                width 2
                gap 3
                active-color "${palette.primary}"
                urgent-color "${palette.error}"
            }

            insert-hint {
                color "${palette.primary}80"
            }
        }

        cursor {
            hide-when-typing
        }

        recent-windows {
            highlight {
                active-color "${palette.primary}"
                urgent-color "${palette.error}"
            }
        }

        hotkey-overlay {
            skip-at-startup
        }

        prefer-no-csd

    debug {
        honor-xdg-activation-with-invalid-serial${extraDebug}
    }

        ${workspaces}

        window-rule {
            match app-id=r#"^discord$"#
            match app-id=r#"^element$"#
            match app-id=r#"^slack$"#
            match app-id=r#"^thunderbird$"#
            open-on-workspace "2"
            default-column-display "tabbed"
        }

        window-rule {
            geometry-corner-radius 12
            clip-to-geometry true
        }

        window-rule {
            match app-id=r#"^mpv$"#
            match app-id=r#"^com\.gabm\.satty$"#
            match app-id=r#"^scrcpy$"#
            match title=r#"^Picture-in-Picture$"#
            open-floating true
        }

        layer-rule {
            match namespace="^noctalia-backdrop$"
            place-within-backdrop true
        }

        binds {
            Mod+Shift+Slash { show-hotkey-overlay; }

        Mod+Return hotkey-overlay-title="Open a Terminal: foot" { spawn "${foot}"; }
            Mod+D hotkey-overlay-title="Run an Application" { ${noctalia.launcher}; }
            Mod+E hotkey-overlay-title="Open a File Manager: Thunar" { spawn "thunar"; }
            Super+Alt+L hotkey-overlay-title="Lock the Screen" { ${noctalia.lock}; }

            XF86AudioRaiseVolume allow-when-locked=true { ${noctalia.volumeUp}; }
            XF86AudioLowerVolume allow-when-locked=true { ${noctalia.volumeDown}; }
            XF86AudioMute allow-when-locked=true { ${noctalia.mute}; }
            XF86AudioMicMute allow-when-locked=true { ${noctalia.micMute}; }
            XF86MonBrightnessUp allow-when-locked=true { ${noctalia.brightnessUp}; }
            XF86MonBrightnessDown allow-when-locked=true { ${noctalia.brightnessDown}; }

            XF86AudioPlay allow-when-locked=true { ${noctalia.mediaToggle}; }
            XF86AudioStop allow-when-locked=true { ${noctalia.mediaStop}; }
            XF86AudioPrev allow-when-locked=true { ${noctalia.mediaPrev}; }
            XF86AudioNext allow-when-locked=true { ${noctalia.mediaNext}; }

            Mod+N { ${noctalia.notifications}; }

            Mod+O repeat=false { toggle-overview; }
            Mod+Shift+Q repeat=false { close-window; }

        ${directional "Mod+" ["focus-column-left" "focus-window-down" "focus-window-up" "focus-column-right"]}

        ${directional "Mod+Shift+" ["move-column-left" "move-window-down" "move-window-up" "move-column-right"]}

            Mod+Home { focus-column-first; }
            Mod+End { focus-column-last; }
            Mod+Ctrl+Home { move-column-to-first; }
            Mod+Ctrl+End { move-column-to-last; }

        ${directional "Mod+Ctrl+" ["focus-monitor-left" "focus-monitor-down" "focus-monitor-up" "focus-monitor-right"]}

        ${directional "Mod+Shift+Ctrl+" ["move-column-to-monitor-left" "move-column-to-monitor-down" "move-column-to-monitor-up" "move-column-to-monitor-right"]}

            Mod+Tab { focus-workspace-previous; }

            Mod+Page_Down { focus-workspace-down; }
            Mod+Page_Up { focus-workspace-up; }
            Mod+U { focus-workspace-down; }
            Mod+I { focus-workspace-up; }
            Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
            Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
            Mod+Ctrl+U { move-column-to-workspace-down; }
            Mod+Ctrl+I { move-column-to-workspace-up; }
            Mod+Shift+Page_Down { move-workspace-down; }
            Mod+Shift+Page_Up { move-workspace-up; }
            Mod+Shift+U { move-workspace-down; }
            Mod+Shift+I { move-workspace-up; }

            Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
            Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
            Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
            Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }
            Mod+WheelScrollRight { focus-column-right; }
            Mod+WheelScrollLeft { focus-column-left; }
            Mod+Ctrl+WheelScrollRight { move-column-right; }
            Mod+Ctrl+WheelScrollLeft { move-column-left; }
            Mod+Shift+WheelScrollDown { focus-column-right; }
            Mod+Shift+WheelScrollUp { focus-column-left; }
            Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
            Mod+Ctrl+Shift+WheelScrollUp { move-column-left; }

        ${workspaceBinds}

            Mod+BracketLeft { consume-or-expel-window-left; }
            Mod+BracketRight { consume-or-expel-window-right; }
            Mod+Comma { consume-window-into-column; }
            Mod+Period { ${noctalia.emoji}; }

            Mod+R { switch-preset-column-width; }
            Mod+Shift+R { switch-preset-column-width-back; }
            Mod+Ctrl+Shift+R { switch-preset-window-height; }
            Mod+Ctrl+R { reset-window-height; }
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }
            Mod+M { maximize-window-to-edges; }
            Mod+Ctrl+F { expand-column-to-available-width; }
            Mod+Shift+C { center-column; }
        Mod+C { ${noctalia.calculator}; }
            Mod+Ctrl+C { center-visible-columns; }
            Mod+Minus { set-column-width "-10%"; }
            Mod+Equal { set-column-width "+10%"; }
            Mod+Shift+Minus { set-window-height "-10%"; }
            Mod+Shift+Equal { set-window-height "+10%"; }
            Mod+Shift+Space { toggle-window-floating; }
            Mod+Space { switch-focus-between-floating-and-tiling; }
            Mod+W { toggle-column-tabbed-display; }

            Print { ${noctalia.screenshotRegion}; }
            Ctrl+Print { ${noctalia.screenshotScreen}; }
            Shift+Print { ${noctalia.screenshotAnnotate}; }

            Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
            Mod+Shift+E { quit; }
            Ctrl+Alt+Delete { quit; }
            Mod+Shift+P { power-off-monitors; }
        }
  '';

  configFile = pkgs.writeTextFile {
    name = "niri-config.kdl";
    text = configText;
    checkPhase = ''
      ${lib.getExe cfg.package} validate --config "$target"
    '';
  };
in {
  options.localModules.niri = {
    enable = lib.mkEnableOption "niri";

    package = lib.mkPackageOption pkgs "niri" {};

    extraDebug = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "disable-cursor-plane";
      description = ''
        Extra entries for the `debug` node.
      '';
    };

    workspaceOutputs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"1" = "DP-1";};
      description = ''
        Output each named workspace opens on. niri takes a single output per
        workspace, not an ordered preference list; when it is absent the
        workspace falls back to the primary monitor and returns when it is
        plugged back in.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.xwayland-satellite # niri spawns this on demand for X11 clients
    ];

    systemd.user.packages = [cfg.package];

    services.kanshi.enable = true;

    systemd.user.services.niri-sort-workspaces = {
      Unit = {
        Description = "Keep niri workspaces in their declared order";
        PartOf = ["graphical-session.target"];
        After = ["niri.service"];
      };
      Service = {
        ExecStart = "${lib.getExe sortWorkspaces} --watch";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    xdg.configFile."niri/config.kdl".source = configFile;
  };
}
