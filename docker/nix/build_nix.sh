#!/bin/env bash
set -eou pipefail

nix --version
if [ -d "/workspace" ]; then
    cd /workspace
fi

SYSTEM=$(nix-instantiate --eval -E builtins.currentSystem | tr -d '"')

nix build .#checks.$SYSTEM.psql_15 -L --no-link
nix build .#checks.$SYSTEM.psql_16 -L --no-link

nix build .#psql_15/bin -o psql_15
nix build .#psql_16/bin -o psql_16

# Skip orioledb-17 on x86_64-darwin
if [ "$SYSTEM" != "x86_64-darwin" ]; then
    nix build .#psql_orioledb-17/bin -o psql_orioledb_17
fi

# Copy to S3
nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key ./psql_15
nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key ./psql_16
if [ "$SYSTEM" != "x86_64-darwin" ]; then
    nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key ./psql_orioledb_17
fi
if [ "$SYSTEM" = "aarch64-linux" ]; then
    nix build .#postgresql_15_debug -o ./postgresql_15_debug
    nix build .#postgresql_15_src -o ./postgresql_15_src
    nix build .#postgresql_16_debug -o ./postgresql_16_debug
    nix build .#postgresql_16_src -o ./postgresql_16_src
    nix build .#postgresql_orioledb-17_debug -o ./postgresql_orioledb-17_debug
    nix build .#postgresql_orioledb-17_src -o ./postgresql_orioledb-17_src
    nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key ./postgresql_15_debug-debug
    nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key  ./postgresql_15_src
    nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key ./postgresql_16_debug-debug
    nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key  ./postgresql_16_src
    nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key ./postgresql_orioledb-17_debug-debug
    nix copy --to s3://nix-postgres-artifacts?secret-key=nix-secret-key  ./postgresql_orioledb-17_src
fi
