{
  buildPythonPackage,
  pkgs,
  fetchFromGitHub,
  click,
  psutil,
  setuptools,
}:
buildPythonPackage rec {
  pname = "vfio-isolate";
  version = "0.5.1";

  pyproject = true;
  build-system = [setuptools];

  src = fetchFromGitHub {
    owner = "spheenik";
    repo = pname;
    rev = "c6eb01cab509dfa6a220dc17f44233fa4e93493c";
    sha256 = "sha256-NtvFi57A17Bv1kxhKuSbCPBlZlnW8ykg3+aQHeEZNp8=";
  };

  preConfigure = ''
    sed -i \
      -e 's/psutil~=5.7.0/psutil~=5.9.0/' \
      -e 's/click~=7.1.2/click~=8.1.0/' \
      setup.py
  '';

  propagatedBuildInputs = [
    click
    psutil
  ];

  # Will fail if cgroups aren't mounted
  doCheck = false;

  meta.mainProgram = "vfio-isolate";
}
