# syntax=docker/dockerfile:1.6
ARG postgresql_major=12
ARG postgresql_release=${postgresql_major}.22

# Bump default build arg to build a package from source
# Bump vars.yml to specify runtime package version
ARG postgis_release=3.3.2
ARG pg_cron_release=1.6.2
ARG pgjwt_release=9742dab1b2f297ad3811120db7b21451bca2d3c9
ARG pg_safeupdate_release=1.4
ARG pg_net_release=0.9.2
ARG hypopg_release=1.3.1
ARG pgvector_release=0.4.0
ARG index_advisor_release=0.2.0

FROM postgres:12.22-bookworm as builder
# Install build dependencies
ARG postgresql_major
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    checkinstall \
    cmake \
    postgresql-server-dev-${postgresql_major} \
    && rm -rf /var/lib/apt/lists/*

####################
# 01-postgis.yml
####################
FROM builder as postgis-source
# Download and extract
ARG postgis_release
ADD "https://supabase-public-artifacts-bucket.s3.amazonaws.com/postgis-${postgis_release}.tar.gz" \
    /tmp/postgis.tar.gz
RUN tar -xvf /tmp/postgis.tar.gz -C /tmp && \
    rm -rf /tmp/postgis.tar.gz
# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    protobuf-c-compiler \
    libgeos-dev \
    libproj-dev \
    libgdal-dev \
    libjson-c-dev \
    libxml2-dev \
    libprotobuf-c-dev \
    && rm -rf /var/lib/apt/lists/*
# Build from source
WORKDIR /tmp/postgis-${postgis_release}
RUN ./configure
RUN make -j$(nproc)
# Create debian package
RUN checkinstall -D --install=no --fstrans=no --backup=no --pakdir=/tmp --requires=libgeos-c1v5,libproj25,libjson-c5,libprotobuf-c1,libgdal32 --nodoc

####################
# 04-pg_cron.yml
####################
FROM builder as pg_cron-source
# Download and extract
ARG pg_cron_release
ADD "https://github.com/citusdata/pg_cron/archive/refs/tags/v${pg_cron_release}.tar.gz" \
    /tmp/pg_cron.tar.gz
RUN tar -xvf /tmp/pg_cron.tar.gz -C /tmp && \
    rm -rf /tmp/pg_cron.tar.gz
# Build from source
WORKDIR /tmp/pg_cron-${pg_cron_release}
RUN make -j$(nproc)
# Create debian package
RUN checkinstall -D --install=no --fstrans=no --backup=no --pakdir=/tmp --nodoc

####################
# 06-pgjwt.yml
####################
FROM builder as pgjwt-source
# Download and extract
ARG pgjwt_release
ADD "https://github.com/michelp/pgjwt.git#${pgjwt_release}" \
    /tmp/pgjwt-${pgjwt_release}
# Build from source
WORKDIR /tmp/pgjwt-${pgjwt_release}
RUN make -j$(nproc)
# Create debian package
RUN checkinstall -D --install=no --fstrans=no --backup=no --pakdir=/tmp --pkgversion=1 --nodoc

####################
# 09-pg-safeupdate.yml
####################
FROM builder as pg-safeupdate-source
# Download and extract
ARG pg_safeupdate_release
ADD "https://github.com/eradman/pg-safeupdate/archive/refs/tags/${pg_safeupdate_release}.tar.gz" \
    /tmp/pg-safeupdate.tar.gz
RUN tar -xvf /tmp/pg-safeupdate.tar.gz -C /tmp && \
    rm -rf /tmp/pg-safeupdate.tar.gz
# Build from source
WORKDIR /tmp/pg-safeupdate-${pg_safeupdate_release}
RUN make -j$(nproc)
# Create debian package
RUN checkinstall -D --install=no --fstrans=no --backup=no --pakdir=/tmp --nodoc

####################
# 15-pg_net.yml
####################
FROM builder as pg_net-source
# Download and extract
ARG pg_net_release
ADD "https://github.com/supabase/pg_net/archive/refs/tags/v${pg_net_release}.tar.gz" \
    /tmp/pg_net.tar.gz
RUN tar -xvf /tmp/pg_net.tar.gz -C /tmp && \
    rm -rf /tmp/pg_net.tar.gz
# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-gnutls-dev \
    && rm -rf /var/lib/apt/lists/*
# Build from source
WORKDIR /tmp/pg_net-${pg_net_release}
RUN make -j$(nproc)
# Create debian package
RUN checkinstall -D --install=no --fstrans=no --backup=no --pakdir=/tmp --requires=libcurl3-gnutls --nodoc

####################
# 26-hypopg.yml
####################
FROM builder as hypopg-source
# Download and extract
ARG hypopg_release
ADD "https://github.com/HypoPG/hypopg/archive/refs/tags/${hypopg_release}.tar.gz" \
    /tmp/hypopg.tar.gz
RUN tar -xvf /tmp/hypopg.tar.gz -C /tmp && \
    rm -rf /tmp/hypopg.tar.gz
# Build from source
WORKDIR /tmp/hypopg-${hypopg_release}
RUN make -j$(nproc)
# Create debian package
RUN checkinstall -D --install=no --fstrans=no --backup=no --pakdir=/tmp --nodoc

####################
# 28-pgvector.yml
####################
FROM builder as pgvector-source
ARG pgvector_release
ADD "https://github.com/pgvector/pgvector/archive/refs/tags/v${pgvector_release}.tar.gz" \
    /tmp/pgvector.tar.gz
RUN tar -xvf /tmp/pgvector.tar.gz -C /tmp && \
    rm -rf /tmp/pgvector.tar.gz
# Build from source
WORKDIR /tmp/pgvector-${pgvector_release}
RUN make -j$(nproc)
# Create debian package
RUN checkinstall -D --install=no --fstrans=no --backup=no --pakdir=/tmp --nodoc

######################
# 30-index_advisor.yml
######################
FROM builder as index_advisor
ARG index_advisor_release
ADD "https://github.com/olirice/index_advisor/archive/refs/tags/v${index_advisor_release}.tar.gz" \
    /tmp/index_advisor.tar.gz
RUN tar -xvf /tmp/index_advisor.tar.gz -C /tmp && \
    rm -rf /tmp/index_advisor.tar.gz
# Build from source
WORKDIR /tmp/index_advisor-${index_advisor_release}
RUN make -j$(nproc)
# Create debian package
RUN checkinstall -D --install=no --fstrans=no --backup=no --pakdir=/tmp --nodoc

####################
# Collect extension packages
####################
FROM scratch as extensions
COPY --from=postgis-source /tmp/*.deb /tmp/
COPY --from=pg_cron-source /tmp/*.deb /tmp/
COPY --from=pgjwt-source /tmp/*.deb /tmp/
COPY --from=pg-safeupdate-source /tmp/*.deb /tmp/
COPY --from=pg_net-source /tmp/*.deb /tmp/
COPY --from=hypopg-source /tmp/*.deb /tmp/
COPY --from=pgvector-source /tmp/*.deb /tmp/
COPY --from=index_advisor /tmp/*.deb /tmp/

####################
# Build final image
####################
FROM postgres:12.22-bookworm as production

# Setup extensions
COPY --from=extensions /tmp /tmp

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    /tmp/*.deb \
    # Needed for anything using libcurl
    # https://github.com/supabase/postgres/issues/573
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* /tmp/*

EXPOSE 5866
