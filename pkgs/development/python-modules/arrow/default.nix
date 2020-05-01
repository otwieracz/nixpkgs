{ stdenv, buildPythonPackage, fetchPypi
, nose, chai, simplejson, backports_functools_lru_cache
, dateutil, pytz
}:

buildPythonPackage rec {
  pname = "arrow";
  version = "0.14.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1d95wyvhzhqij72ai87p6c0ic4f4c17n2b8gydxzab1wqnj7xgj1";
  };

  checkPhase = ''
    nosetests --cover-package=arrow
  '';

  checkInputs = [ nose chai simplejson pytz ];
  propagatedBuildInputs = [ dateutil backports_functools_lru_cache ];

  postPatch = ''
    substituteInPlace setup.py --replace "==1.2.1" ""
  '';

  meta = with stdenv.lib; {
    description = "Python library for date manipulation";
    license     = "apache";
    maintainers = with maintainers; [ thoughtpolice ];
  };
}
