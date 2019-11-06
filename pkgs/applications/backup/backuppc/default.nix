{ stdenv, fetchurl, perl, gnutar, perlPackages, rsync-bpc, ping, coreutils }:

stdenv.mkDerivation rec {
  pname = "backuppc";
  version = "4.3.1";

  src = fetchurl {
    url = "https://github.com/backuppc/backuppc/releases/download/4.3.1/BackupPC-${version}.tar.gz";
    sha256 = "0zxb8l2fhsbk1xw90j8kjf2pf37l9a0c556y465a5lcq0dvib0aq";
  };

  buildInputs = with perlPackages; [ BackupPCXS FileListing CGI ];
  nativeBuildInputs = [ perl ];

#  preConfigure = ''
#    echo "preparing makeDist"
#
#    substituteInPlace makeDist --replace "perl -Ilib" "${perl}/bin/perl -Ilib"
#    substituteInPlace makeDist --replace "/usr/bin/perl" "${perl}/bin/perl"
#  '';


  installPhase = ''
    mkdir -pv $out/bin
    #mkdir -pv $out/lib/BackupPC/{CGI,Config,Lang,Storage,Xfer,Zip}
    #mkdir -pv $out/share/backuppc/{html,cgi}
    #mkdir -pv $out/share/doc/BackupPC
    CGIDIR=$out/usr/lib/backuppc

#    echo "running makeDist"
#    ${perl}/bin/perl ./makeDist --nosyntaxcheck --nolangcheck --version $version

    ${perl}/bin/perl configure.pl                  \
        --batch                                    \
        --no-fhs \
        --uid-ignore \
        --backuppc-user $(whoami) \
        --scgi-port 5000 \
        --config-dir $out/etc/BackupPC \
        --data-dir $out/data/BackupPC                  \
        --hostname 127.0.0.1                       \
        --html-dir $out/share/backuppc/html          \
        --html-dir-url /BackupPC                   \
        --install-dir $out \
#        --cgi-dir $out/share/backuppc/cgi        \

#    substituteInPlace remotebox --replace "\$Bin/" "\$Bin/../"
#    install -v -t $out/bin remotebox
#    wrapProgram $out/bin/remotebox --prefix PERL5LIB : $PERL5LIB
#
#    cp -av docs/ share/ $out
#
#    mkdir -pv $out/share/applications
#    cp -pv packagers-readme/*.desktop $out/share/applications
  '';

  meta = with stdenv.lib; {
    description = "BackupPC is a high-performance, enterprise-grade system for backing up to a server's disk.";
    homepage = http://backuppc.sourceforge.net/;
    license = licenses.gpl3;
    platforms = platforms.unix;
    maintainers = with stdenv.lib.maintainers; [ otwieracz ];
  };
}
