{ lib, buildPythonPackage, fetchPypi, isPy27
, attrs
, pyrsistent
, six
, functools32
, lockfile
, setuptools_scm
}:

buildPythonPackage rec {
  pname = "jsonschema";
  version = "3.1.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "2fa0684276b6333ff3c0b1b27081f4b2305f0a36cf702a23db50edb141893c3f";
  };

  nativeBuildInputs = [ setuptools_scm ];
  propagatedBuildInputs = [
    attrs
    pyrsistent
    six
    lockfile
  ] ++ lib.optional isPy27 functools32;

  # tests for latest version rely on custom version of betterpaths that is
  # difficult to deal with and isn't used on master
  doCheck = false;

  meta = with lib; {
    homepage = https://github.com/Julian/jsonschema;
    description = "An implementation of JSON Schema validation for Python";
    license = licenses.mit;
    maintainers = with maintainers; [ jakewaksbaum ];
  };
}
