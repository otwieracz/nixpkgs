{ lib
, buildPythonPackage
, fetchPypi
, flask
}:

buildPythonPackage rec {
  pname = "flask-session";
  version = "0.3.1";

  src = fetchPypi {
    inherit version;
    pname = "Flask-Session";
    sha256 = "0cd7h5c236m6smyixnyfrks4spsqp9d65ndk4p400zr8qgh2f753";
  };

  propagatedBuildInputs = [ flask ];

  # RuntimeError: Working outside of application context.
  doCheck = false;

  checkPhase = ''
    nosetests
  '';

  meta = {
    homepage = https://github.com/fengsp/flask-session;
    description = "Server side session extension for Flask";
    license = lib.licenses.mit;
  };
}
