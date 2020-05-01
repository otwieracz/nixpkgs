{ lib
, buildPythonPackage
, fetchPypi
, flask
}:

buildPythonPackage rec {
  pname = "flask-bower";
  version = "1.3.0";

  src = fetchPypi {
    pname = "Flask-Bower";
    inherit version;
    sha256 = "1f5wdhyrcmnyf484wxlab01dramgyh5aj6imbfpwzxvjv204m21v";
  };

  propagatedBuildInputs = [ flask ];

  # RuntimeError: Working outside of application context.
  doCheck = false;

  checkPhase = ''
    nosetests
  '';

  meta = {
    homepage = https://github.com/lobeck/flask-bower;
    description = "Flask extension to serve bower managed assets";
    license = lib.licenses.gpl2;
  };
}
