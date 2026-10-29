{
  lib,
  cmake,
  fetchFromGitHub,
  git,
  perl,
  rustPlatform,
}:
# nixpkgs' redlib predates the wreq switch (TLS fingerprint spoofing).
# Since 2026-10-28 Reddit 403s every anonymous JSON API path; this fork serves
# everything from the Android app's GraphQL operations instead. Go back to
# redlib-org once upstream handles the block.
rustPlatform.buildRustPackage {
  pname = "redlib";
  version = "0.36.0-unstable-2026-10-28";

  src = fetchFromGitHub {
    owner = "polak14";
    repo = "redlib";
    rev = "29f18352cf54be4ffe579f773552acd0c45cdd08";
    hash = "sha256-ShLaYBcSZmW2gQuwJdtE3nhpuzWL+ITkyuCgQ0rNM1o=";
  };

  cargoHash = "sha256-HxOGzNKytC5EHA5Ox6Dor/qQZafEnWYjzKS6HH9fYW8=";

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
