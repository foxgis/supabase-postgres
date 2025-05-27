#!/bin/bash

# 加载.env中的环境变量
set -a; source .env; set +a

# 删除旧容器
docker stop hgdb
docker rm -v hgdb

# 删除旧数据目录并重建
rm -rf data
mkdir data
chmod 777 data

# 运行新容器
docker run -d --name=hgdb \
  -p 5866:5866 \
  -v $PWD/data:/home/highgo/hgdb \
  -e TZ="Asia/Shanghai" \
  -e LANG="en_US.utf8" \
  -e POSTGRES_HOST_AUTH_METHOD="md5" \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_INITDB_ARGS="-A md5 -e sm4 -c 'echo 12345678' -E 'UTF8'" \
  --restart always \
  jingsam/supabase-highgo:latest

# 等待数据库启动
until docker exec hgdb pg_isready -U sysdba -d highgo -q; do
  echo "Waiting for database to start..."
  sleep 1
done

# 复制许可文件
cp hgdb.lic data/

# 更改select version()返回值，以兼容GDAL
docker exec -i hgdb gosu highgo bash <<- "EOF"
  hg_version_gen "PostgreSQL 12.7 (HGDB-SEE V4.5)" "PostgreSQL 12.7 (HGDB-SEE V4.5)" "12.7"
EOF

# 更改数据库配置
docker exec -i -e PGPASSWORD=$POSTGRES_PASSWORD hgdb gosu highgo psql -U sysdba -d highgo <<- "EOF"
  alter system set shared_preload_libraries = pg_stat_statements, pg_cron, pg_net;
  alter system set wal_level = 'logical';
EOF

# 重启数据库使配置生效
docker restart hgdb

# 等待数据库重启动
until docker exec hgdb pg_isready -U sysdba -d highgo -q; do
  echo "Waiting for database to restart..."
  sleep 1
done

# 临时关闭三权分立
docker exec -i -e PGPASSWORD=$POSTGRES_PASSWORD hgdb gosu highgo psql -U syssso -d highgo <<- "EOF"
  select set_secure_param('hg_sepv4','dyn_off');
EOF

# 创建数据库和用户
docker exec -i -e PGPASSWORD=$POSTGRES_PASSWORD hgdb gosu highgo psql -U sysdba -d highgo <<- EOF
  create role postgres superuser login password '$POSTGRES_PASSWORD';
  create database $POSTGRES_DB with owner postgres;
EOF

# 初始化数据库
./initdb.sh

# 恢复三权分立
docker exec -i -e PGPASSWORD=$POSTGRES_PASSWORD hgdb gosu highgo psql -U syssso -d highgo <<- "EOF"
  select set_secure_param('hg_sepv4','on');
EOF