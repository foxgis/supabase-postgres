#!/bin/bash

set -euo pipefail

# 加载.env中的环境变量
set -a; source .env; set +a

# 设置数据库环境变量
export PGDATABASE="${POSTGRES_DB:-postgres}"
export PGHOST="${POSTGRES_HOST:-localhost}"
export PGPORT="${POSTGRES_PORT:-5866}"
export PGPASSWORD="${POSTGRES_PASSWORD:-}"

# 创建数据库用户
psql -v ON_ERROR_STOP=1 --no-password --no-psqlrc -U postgres <<-EOSQL
  create role supabase_admin superuser login password '$POSTGRES_PASSWORD';
  create user supabase_functions_admin noinherit createrole login noreplication password '$POSTGRES_PASSWORD';
EOSQL

# 初始化数据库
./db/migrate.sh