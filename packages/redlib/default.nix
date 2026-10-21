{
  lib,
  cmake,
  fetchFromGitHub,
  git,
  perl,
  rustPlatform,
}:
# nixpkgs' redlib predates the wreq switch (TLS fingerprint spoofing).
rustPlatform.buildRustPackage {
  pname = "redlib";
  version = "0.36.0-unstable-2026-04-24";

  src = fetchFromGitHub {
    owner = "redlib-org";
    repo = "redlib";
    rev = "a4d36e954cf1bd64f209cd8868c5a29edc81b374";
    hash = "sha256-siyD6A12UALQIV7BMd7zu1TaojleTEYtpxPszuhx1/Y=";
  };

  cargoHash = "sha256-eO3c7rlFna3DuO31etJ6S4c7NmcvgvIWZ1KVkNIuUqQ=";

  patches = [
    # Since 2026-10-20 Reddit 403s every post page. Drop once upstream merges
    # https://github.com/redlib-org/redlib/pull/592.
    ./encode-comments-slash.patch
  ];

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
    homepage = "https://github.com/redlib-org/redlib";
    license = lib.licenses.agpl3Only;
    mainProgram = "redlib";
  };
}
