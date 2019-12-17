{ python3Packages, fetchPypi }:

with python3Packages;
buildPythonApplication rec {
  pname = "catt";
  version = "0.10.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "10fzii2x5sc1rrhysk8pgq4yq69b3bb07pkw5slp2a35phxlflpi";
  };

  propagatedBuildInputs = [
    click
    PyChromecast
    youtube-dl
  ];

  doCheck = false;
}
