#!/bin/bash

# 加载环境变量
set -a; source .env; set +a

export PGDATABASE="${POSTGRES_DB:-postgres}"
export PGHOST="${POSTGRES_HOST:-localhost}"
export PGPORT="${POSTGRES_PORT:-5866}"
export PGPASSWORD="${POSTGRES_PASSWORD:-}"

# 创建必要的数据库角色
psql -v ON_ERROR_STOP=1 --no-password --no-psqlrc -U postgres <<-EOSQL
  -- supabase users
  create user supabase_admin with superuser createdb createrole replication bypassrls password '$POSTGRES_PASSWORD';
  create user supabase_auth_admin with createrole noreplication noinherit password '$POSTGRES_PASSWORD';
  create user supabase_storage_admin with createrole noreplication noinherit password '$POSTGRES_PASSWORD';
  create user supabase_functions_admin with createrole noreplication noinherit password '$POSTGRES_PASSWORD';
  create user supabase_replication_admin with replication password '$POSTGRES_PASSWORD';
  create user supabase_etl_admin with replication password '$POSTGRES_PASSWORD';
  create user supabase_read_only_user with bypassrls password '$POSTGRES_PASSWORD';
  create user authenticator with noinherit password '$POSTGRES_PASSWORD';
  create user pgbouncer with password '$POSTGRES_PASSWORD';

  -- supabase roles
  create role anon inherit;
  create role authenticated inherit;
  create role service_role inherit bypassrls;
  create role dashboard_user createdb createrole replication;
EOSQL

# 执行数据库初始化脚本
chmod +x ./db/migrate.sh
./db/migrate.sh
