{ stdenv, buildPythonPackage, fetchPypi, python
, nose, mock, vcversioner, functools32
, setuptools_scm
, pyrsistent
}:

buildPythonPackage rec {
  pname = "jsonschema";
  version = "3.1.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "2fa0684276b6333ff3c0b1b27081f4b2305f0a36cf702a23db50edb141893c3f";
  };

  nativeBuildInputs = [ setuptools_scm ];

  checkInputs = [ nose mock vcversioner ];
  propagatedBuildInputs = [ functools32 pyrsistent ];

  postPatch = ''
    substituteInPlace jsonschema/tests/test_jsonschema_test_suite.py \
      --replace "python" "${python.pythonForBuild.interpreter}"
  '';

  checkPhase = ''
    nosetests
  '';

  meta = with stdenv.lib; {
    homepage = https://github.com/Julian/jsonschema;
    description = "An implementation of JSON Schema validation for Python";
    license = licenses.mit;
    maintainers = with maintainers; [ domenkozar ];
  };
}
