{ lib
, stdenv
, fetchFromGitHub
, openssl
, postgresql
, postgresqlTestHook
, readline
, testers
, zlib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pg_repack";
  version = "1.5.2";

  buildInputs = postgresql.buildInputs ++ [ postgresql ];

  src = fetchFromGitHub {
    owner = "reorg";
    repo = "pg_repack";
    rev = "85b64c6d4f599b2988343c4e7121acab505c9006";
    hash = "sha256-lAuLI+vupusvn3uTzQ9OaLqkEfUVMCAwU9R70tTbb8Y=";
  };

  installPhase = ''
    install -D bin/pg_repack -t $out/bin/
    install -D lib/pg_repack${postgresql.dlSuffix} -t $out/lib/
    install -D lib/{pg_repack--${finalAttrs.version}.sql,pg_repack.control} -t $out/share/postgresql/extension
  '';

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
    };
    extension = stdenv.mkDerivation {
      name = "plpgsql-check-test";
      dontUnpack = true;
      doCheck = true;
      buildInputs = [ postgresqlTestHook ];
      nativeCheckInputs = [ (postgresql.withPackages (ps: [ ps.pg_repack ])) ];
      postgresqlTestUserOptions = "LOGIN SUPERUSER";
      failureHook = "postgresqlStop";
      checkPhase = ''
        runHook preCheck
        psql -a -v ON_ERROR_STOP=1 -c "CREATE EXTENSION pg_repack;"
        runHook postCheck
      '';
      installPhase = "touch $out";
    };
  };

  meta = with lib; {
    description = "Reorganize tables in PostgreSQL databases with minimal locks";
    longDescription = ''
      pg_repack is a PostgreSQL extension which lets you remove bloat from tables and indexes, and optionally restore
      the physical order of clustered indexes. Unlike CLUSTER and VACUUM FULL it works online, without holding an
      exclusive lock on the processed tables during processing. pg_repack is efficient to boot,
      with performance comparable to using CLUSTER directly.
    '';
    homepage = "https://github.com/reorg/pg_repack";
    license = licenses.bsd3;
    maintainers = with maintainers; [ samrose ];
    inherit (postgresql.meta) platforms;
    mainProgram = "pg_repack";
  };
})
