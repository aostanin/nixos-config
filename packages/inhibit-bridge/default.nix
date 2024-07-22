{
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "inhibit-bridge";
  version = "1.2.4";

  src = fetchFromGitHub {
    owner = "bdwalton";
    repo = "inhibit-bridge";
    rev = "v${version}";
    sha256 = "sha256-UEJtQ7z9O+14a/5vEGjMWnFOcrTapLgWYcPBmSGJmnk=";
  };

  vendorHash = "sha256-DGxvhBmEdPqfupBLQSotkwhGvUDYBsAH5d+27DAOhQY=";

  meta.mainProgram = "inhibit-bridge";
}
