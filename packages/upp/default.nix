{
  stdenv,
  buildPythonPackage,
  fetchPypi,
  click,
  setuptools,
}:
buildPythonPackage rec {
  pname = "upp";
  version = "0.1.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-hK7Da2XNiPzmzp1yjbEQA0TYRNY9RS0xM7m/54oBdjI=";
  };

  propagatedBuildInputs = [click setuptools];
}
