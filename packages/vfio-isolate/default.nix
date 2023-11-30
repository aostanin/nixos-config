{
  buildPythonPackage,
  pkgs,
  fetchFromGitHub,
  click,
  psutil,
}:
buildPythonPackage rec {
  pname = "vfio-isolate";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "spheenik";
    repo = pname;
    rev = "20cc2e4a6dd863f563c07b9cda1617dbe729fbf8";
    sha256 = "sha256-K8DDzMQ18U+jiSsA/UltT81C6pnBrc4MZ+mGJNEdj9o=";
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
}
