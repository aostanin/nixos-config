{ buildPythonPackage, pkgs, fetchFromGitHub, click, parsimonious, psutil }:

buildPythonPackage rec {
  pname = "vfio-isolate";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "spheenik";
    repo = pname;
    rev = "20cc2e4a6dd863f563c07b9cda1617dbe729fbf8";
    sha256 = "1nlg3p8j91p9cw6cxbf1k7m45kagdm4zs01bi6ilzw9mqk6c7h1b";
  };

  preConfigure = ''
    sed -i \
      -e 's/psutil~=5.7.0/psutil~=5.9.0/' \
      -e 's/click~=7.1.2/click~=8.1.0/' \
      -e 's/parsimonious~=0.8.1/parsimonious~=0.9.0/' \
      setup.py
  '';

  propagatedBuildInputs = [
    click
    parsimonious
    psutil
  ];

  # Will fail if cgroups aren't mounted
  doCheck = false;
}
