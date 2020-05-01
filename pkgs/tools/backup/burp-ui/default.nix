{ stdenv , python3Packages, fetchurl }:

with python3Packages;

buildPythonApplication rec {
  pname = "burp-ui";
  version = "0.6.6";

  src = fetchurl {
    url = "https://git.ziirish.me/ziirish/burp-ui/-/archive/b5686aad5d5211d56c8eb78cae03d79dc66f21b8/burp-ui-b5686aad5d5211d56c8eb78cae03d79dc66f21b8.tar.bz2";
    sha256 = "1c6g7kkjkg4f002h8b0xcn1hvvg7dcqrrzc1fdm83n4kqhmqk220";
  };

  checkInputs = with python3Packages; [ sqlalchemy-utils flask_migrate redis celery flask_testing nose coverage flask-session mock flask_migrate flask_sqlalchemy mockredispy ];

  propagatedBuildInputs = with python3Packages; [ trio flask flask_login flask-babel flask-bower flask_wtf flask-restplus flask-session flask-caching wtforms arrow pluginbase tzlocal pyopenssl configobj async_generator click ];

  doCheck = false;

  meta = with stdenv.lib; {
    homepage = https://git.ziirish.me/ziirish/burp-ui;
    description = "Burp-UI is a web-ui for burp backup written in python with Flask and jQuery/Bootstrap";
    license = licenses.bsd3;
    maintainers = with maintainers; [ otwieracz ];
  };
}
