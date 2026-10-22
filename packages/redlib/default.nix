{
  lib,
  cmake,
  fetchFromGitHub,
  git,
  perl,
  rustPlatform,
}:
# nixpkgs' redlib predates the wreq switch (TLS fingerprint spoofing).
# Since 2026-10-22 Reddit 403s every anonymous comments API path, encoded or
# not; this fork falls back to scraping the shreddit HTML. Go back to
# redlib-org once upstream handles the block.
rustPlatform.buildRustPackage {
  pname = "redlib";
  version = "0.36.0-unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "polak14";
    repo = "redlib";
    rev = "4055fda1a5355f1507b23108795d827a16794b58";
    hash = "sha256-7VRaXfYDPhwqgUCSCYCmO36XKdNQ5zEPrpP/E/BQh5g=";
  };

  cargoHash = "sha256-An6ai9CWrskjfPqmUN/z9rqZYsZp0Tjhp1ODvUnPAuw=";

  # boring-sys2 builds BoringSSL with cmake and applies its patches with git.
  nativeBuildInputs = [cmake git perl rustPlatform.bindgenHook];
  dontUseCmakeConfigure = true;

  # services.redlib layers on this unit (DynamicUser comes from it).
  postInstall = ''
    install -Dm444 contrib/redlib.service $out/lib/systemd/system/redlib.service
    substituteInPlace $out/lib/systemd/system/redlib.service \
      --replace-fail /usr/bin/redlib $out/bin/redlib
  '';

  # Most tests hit Reddit.
  doCheck = false;

  meta = {
    description = "Private front-end for Reddit";
    homepage = "https://github.com/polak14/redlib";
    license = lib.licenses.agpl3Only;
    mainProgram = "redlib";
  };
}
