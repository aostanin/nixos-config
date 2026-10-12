{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.localModules.strata;

  stateDir = "/var/lib/strata";
  configFile = "/run/strata/strata.json";

  package = cfg.package.override {inherit (cfg) cpuArch;};

  runConfig = pkgs.writeText "strata.json" (builtins.toJSON ({
      exe = "${package}/share/strata/engine/strata";
      cwd = stateDir;
      log = "${stateDir}/strata.log";
    }
    // cfg.settings));

  # setup.py refreshes the MTP folder's draft vocabulary before every start;
  # without it the folder keeps whichever release last wrote it.
  args = cfg.settings.args or [];
  mtpDir = let
    i = lib.lists.findFirstIndex (a: a == "--mtp") null args;
  in
    if i == null
    then null
    else lib.elemAt args (i + 1);
  draftVocab =
    {
      cjk = "draft_vocab.bin";
      en = "draft_vocab_en.bin";
      cyrillic = "draft_vocab_cyrillic.bin";
      fr = "draft_vocab_fr.bin";
    }
    .${
      cfg.settings.draft_vocab or "cjk"
    };
in {
  options.localModules.strata = {
    enable = lib.mkEnableOption "Strata";

    package = lib.mkPackageOption pkgs "strata" {};

    cpuArch = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "raptorlake";
      description = "-march to build for; null builds the portable AVX2 baseline.";
    };

    settings = lib.mkOption {
      type = (pkgs.formats.json {}).type;
      default = {};
      description = ''
        The engine config `serve/server.py --config` reads, as setup.py writes
        it. `exe`, `cwd` and `log` default to the package and the state dir.
      '';
    };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = package;
      description = "`package` built for `cpuArch`.";
    };

    launcher = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Starts the server on the port given as its only argument.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = ["d ${stateDir} 0750 root root -"];

    # The web UI's Settings view rewrites the config it was started with, so
    # every start gets a fresh copy.
    localModules.strata.launcher = pkgs.writeShellScript "strata-launch" ''
      install -D -m 644 ${runConfig} ${configFile}
      ${lib.optionalString (mtpDir != null) ''
        ${lib.getExe' pkgs.diffutils "cmp"} -s ${package}/share/strata/data/${draftVocab} ${mtpDir}/draft_vocab.bin \
          || install -m 644 ${package}/share/strata/data/${draftVocab} ${mtpDir}/draft_vocab.bin
      ''}
      exec ${lib.getExe package} --engine strata --config ${configFile} --port "$1"
    '';
  };
}
