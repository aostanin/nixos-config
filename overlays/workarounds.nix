final: prev: let
  # localLib.filterAvailable drops broken packages, so darwin skips them
  # instead of trying to build them.
  brokenOnDarwin = pkg:
    pkg.overrideAttrs (old: {
      meta = (old.meta or {}) // {broken = (old.meta.broken or false) || prev.stdenv.hostPlatform.isDarwin;};
    });
in {
  # Fail on aarch64-darwin as of 2026-10-14: manifold's tests crash (blender,
  # openscad-unstable); qtwebengine doesn't compile (f3d, via openusd).
  blender = brokenOnDarwin prev.blender;
  f3d = brokenOnDarwin prev.f3d;
  openscad-unstable = brokenOnDarwin prev.openscad-unstable;

  # Blockstream Jade needs cbor2
  hwi = prev.hwi.overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [prev.python3Packages.cbor2];
  });

  # meshcentral's bundled node-gyp (8.4.1) imports distutils, removed in
  # Python 3.12; building the native bufferutil dep fails. Give node-gyp a
  # Python with setuptools (restores the distutils shim). Surfaces on aarch64
  # since x86 is cached.
  meshcentral = prev.meshcentral.overrideAttrs (old: let
    python = final.python3.withPackages (ps: [ps.setuptools]);
  in {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [python];
    npm_config_python = "${python}/bin/python3";
  });

  # The Nix builds pass --ignore-scripts, so the patch-package postinstall never
  # runs and patched exports are undefined (React #130 on opening any chat).
  # ref: https://github.com/getpaseo/paseo/issues/7673
  paseo = prev.paseo.overrideAttrs (old: {
    preBuild = (old.preBuild or "") + "npm run postinstall\n";
    # Upstream's install copies node_modules/node-pty/prebuilds/, but node-pty
    # lives under packages/server/node_modules, so terminals can't load pty.node.
    postInstall =
      (old.postInstall or "")
      + ''
        plat=$(node -p 'process.platform + "-" + process.arch')
        for pty in $(find . -path ./node_modules/.cache -prune -o -type d -name node-pty -print); do
          if [ -d "$pty/prebuilds/$plat" ] && [ -d "$out/lib/paseo/$pty" ]; then
            mkdir -p "$out/lib/paseo/$pty/prebuilds"
            cp -a "$pty/prebuilds/$plat" "$out/lib/paseo/$pty/prebuilds/"
          fi
        done
      '';
  });
  paseo-desktop = prev.paseo-desktop.overrideAttrs (old: {
    preBuild = (old.preBuild or "") + "npm run postinstall\n";
  });

  # podman 5.8.7/5.8.8 refuse to copy through /var/run -> /run, failing every
  # forgejo runner job at checkout; 5.8.9 has the fix.
  # ref: https://github.com/podman-container-tools/podman/issues/29805
  podman = let
    version = "5.8.9";
  in
    if prev.lib.versionOlder prev.podman.version version
    then
      prev.podman.overrideAttrs (_: {
        inherit version;
        src = prev.fetchFromGitHub {
          owner = "podman-container-tools";
          repo = "podman";
          tag = "v${version}";
          hash = "sha256-nIWwG5QyIent0vJtEm8zDQLbqfTZmD4oKMbf2N5r2wA=";
        };
      })
    else prev.lib.warn "overlays/workarounds.nix: nixpkgs has podman ${prev.podman.version}, drop the podman override" prev.podman;

  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (pyFinal: pyPrev: {
        # anyio 4.15 makes fastmcp 3.2.3's stateful proxy tests fail with "exit
        # a cancel scope that isn't the current task's"; Hydra has no build.
        fastmcp =
          if pyPrev.fastmcp.version == "3.2.3"
          then
            pyPrev.fastmcp.overridePythonAttrs (old: {
              disabledTestPaths =
                (old.disabledTestPaths or [])
                ++ map (t: "tests/server/providers/proxy/test_stateful_proxy_client.py::TestStatefulProxyClient::${t}") [
                  "test_concurrent_log_requests_no_mixing"
                  "test_stateful_proxy"
                  "test_multi_proxies_no_mixing"
                ];
            })
          else prev.lib.warn "overlays/workarounds.nix: nixpkgs has fastmcp ${pyPrev.fastmcp.version}, check whether the fastmcp test skips are still needed" pyPrev.fastmcp;

        # Pillow 13 rejects imageio 2.37.2's 16-bit PNG handling ("Invalid mode
        # for data type"); Hydra has no build.
        imageio =
          if pyPrev.imageio.version == "2.37.2"
          then
            pyPrev.imageio.overridePythonAttrs (old: {
              disabledTestPaths =
                (old.disabledTestPaths or [])
                ++ [
                  "tests/test_pillow.py::test_png_16bit"
                  "tests/test_pillow_legacy.py::test_png"
                ];
            })
          else prev.lib.warn "overlays/workarounds.nix: nixpkgs has imageio ${pyPrev.imageio.version}, check whether the imageio test skips are still needed" pyPrev.imageio;
      })
    ];

  # The wrapper writes autoconfig.js where Firefox reads it on macOS;
  # Thunderbird only reads defaults/pref, so mozilla.cfg never runs.
  thunderbird = prev.thunderbird.overrideAttrs (old:
    prev.lib.optionalAttrs prev.stdenv.isDarwin {
      buildCommand =
        old.buildCommand
        + ''
          resources=$out/Applications/Thunderbird.app/Contents/Resources
          mkdir -p $resources/defaults/pref
          cp $resources/browser/defaults/preferences/autoconfig.js $resources/defaults/pref/
        '';
    });

  # llama-swap's sendLoadingState chunks omit choices[].index, and litellm
  # 1.106 500s at the end of any stream containing one, losing the reply.
  # Fixed on litellm main, not yet in a stable release.
  # ref: https://github.com/BerriAI/litellm/issues/46047
  unstable =
    prev.unstable
    // {
      llama-swap = prev.unstable.llama-swap.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace internal/router/loading.go \
              --replace-fail 'Delta Delta `json:"delta"`' 'Index int `json:"index"`; Delta Delta `json:"delta"`'
          '';
      });
    };
}
