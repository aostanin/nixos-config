{ buildPythonPackage, pkgs, fetchFromGitHub, click, parsimonious, psutil }:

buildPythonPackage rec {
  pname = "vfio-isolate";
  version = "master";

  src = fetchFromGitHub {
    owner = "spheenik";
    repo = pname;
    rev = "6c16cf363a627f02202586a17df58522e097ef10";
    sha256 = "03n53ylrdsp7qpcyra7qmx8gbjrf16hyipm0777kqfy1qy8pmv45";
  };

  propagatedBuildInputs = [
    click
    parsimonious
    psutil
  ];
}
