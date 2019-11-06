{ stdenv, fetchFromGitHub, perl, libiconv, zlib, popt
, enableACLs ? !(stdenv.isDarwin || stdenv.isSunOS || stdenv.isFreeBSD), acl ? null
}:

assert enableACLs -> acl != null;

stdenv.mkDerivation rec {
  pname = "rsync-bpc";
  version = "3.1.2.1";

  src = fetchFromGitHub {
    owner = "backuppc";
    repo = "rsync-bpc";
    rev = version;
    sha256 = "0n45rmrd872b5ql2sd8cgwfzbfwp7vcxmfn7px3wfyf6hhmcsiz6";
  };

  meta = with stdenv.lib; {
    description = "Rsync-bpc is a customized version of rsync that is used as part of BackupPC";
    homepage = http://backuppc.sourceforge.net/;
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with stdenv.lib.maintainers; [ otwieracz ];
  };

  buildInputs = [libiconv zlib popt] ++ stdenv.lib.optional enableACLs acl;
  nativeBuildInputs = [perl];

  configureFlags = ["--with-nobody-group=nogroup"];
}
