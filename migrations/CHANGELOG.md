# 相对于原版的改动

## init-scripts
1. 修改`00000000000000-initial-schema.sql`
    - `create user`、`create role login`必须加密码。（瀚高数据库限制）
    - 注释掉`grant pg_read_all_data to supabase_read_only_user;`。（PG12无pg_read_all_data角色）
    - 增加`create extension postgis`。（pg_tileserv\pg_featureserv要求）
    - `anon`、`authenticated`、`service_role`增加`inherit`属性。（瀚高数据库限制）
    - `anon`和`authenticated`角色的`statement_timeout`设置为60s。
2. 修改`00000000000001-auth-schema.sql`
    - `supabase_auth_admin`增加密码。（瀚高数据库限制）
    - 增加`GRANT USAGE ON SCHEMA extensions TO supabase_auth_admin;`。（为了调用gen_rand_uuid函数）
    - `search_path`增加`extensions`。（为了调用gen_rand_uuid函数）
3. 修改`00000000000002-storage-schema.sql`
    - `supabase_storage_admin`增加密码。（瀚高数据库限制）
    - 增加`GRANT USAGE ON SCHEMA extensions TO supabase_storage_admin;`。（为了调用gen_rand_uuid函数）
    - `search_path`增加`extensions`。（为了调用gen_rand_uuid函数）
4. 修改`00000000000003-post-setup.sql`
    - 增加`db`参数。（用来设置数据库名，而不是默认postgres数据库）
5. 修改`99-jwt.sql`
    - 增加`db`参数。（用来设置数据库名，而不是默认postgres数据库）

## migrations

1. 排除`00-extensions.sql`。（pg_stat_statements默认已安装）
2. 修改`10000000000000_demote-postgres.sql`。
    - 注释`GRANT ALL ON DATABASE postgres TO postgres;`。（非必须）
    - 注释`ALTER ROLE postgres NOSUPERUSER CREATEDB CREATEROLE LOGIN REPLICATION BYPASSRLS;`（非必要）
3. 修改`20221028101028_set_authenticator_timeout.sql`
    - 将`authenticator`角色的`statement_timeout`设置为60s。
4. 注释`20230529180330_alter_api_roles_for_inherit.sql`。（内容已经在00000000000000-initial-schema.sql实现）
5. 修改`20240606060239_grant_predefined_roles_to_postgres.sql`
    - 去除`pg_read_all_data`角色。（PG12无此角色）