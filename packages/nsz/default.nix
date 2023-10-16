{
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  fetchPypi,
  pycryptodome,
  wcwidth,
  six,
  hypothesis,
}: let
  blessed = buildPythonPackage rec {
    pname = "blessed";
    version = "1.17.10";

    doCheck = false;

    src = fetchPypi {
      inherit pname version;
      sha256 = "09kcz6w87x34a3h4r142z3zgw0av19cxn9jrbz52wkpm1534dfaq";
    };

    propagatedBuildInputs = [wcwidth six];
  };

  enlighten = buildPythonPackage rec {
    pname = "enlighten";
    version = "1.6.2";

    propagatedBuildInputs = [
      blessed
    ];

    src = fetchFromGitHub {
      owner = "Rockhopper-Technologies";
      repo = "enlighten";
      rev = version;
      sha256 = "0hslqiv10qqab7w4l0yxjax8xfn9cfi4gxqw2ss3xa9ndsaaswqh";
    };
  };

  zstandard = buildPythonPackage rec {
    pname = "zstandard";
    version = "0.14.0";

    propagatedBuildInputs = [
      hypothesis
    ];

    src = fetchPypi {
      inherit pname version;
      sha256 = "0lkn7n3bfp7zip6hkqwkqwc8pxmhhs4rr699k77h51rfln6kjllh";
    };
  };
in
  buildPythonPackage rec {
    pname = "nsz";
    version = "4.5.0";

    doCheck = false;

    propagatedBuildInputs = [
      pycryptodome
      enlighten
      zstandard
    ];

    src = fetchFromGitHub {
      owner = "nicoboss";
      repo = "nsz";
      rev = version;
      hash = "sha256-/46qOQEuzSBmnFG0XW4z71HAHpuyqhia29KQkUlDsgg=";
    };
  }
