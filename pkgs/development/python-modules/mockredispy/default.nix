{ lib
, buildPythonPackage
, fetchPypi
, redis
, nose
}:

buildPythonPackage rec {
  pname = "mockredispy";
  version = "2.9.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0im46rqg0xa67bs57hpdrx0gim3x6hardk6bphdx8azkp3dgmblc";
  };

  propagatedBuildInputs = [ redis nose ];

  meta = {
    homepage = https://github.com/locationlabs/mockredis;
    description = "Mock for redis-py";
    license = "Apache-2.0";
  };
}
