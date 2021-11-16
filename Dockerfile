# This file is auto generated from it's template,
# see citusdata/tools/packaging_automation/templates/docker/latest/latest.tmpl.dockerfile.
FROM postgres:14.0
ARG VERSION=10.2.2
LABEL maintainer="Citus Data https://citusdata.com" \
      org.label-schema.name="Citus" \
      org.label-schema.description="Scalable PostgreSQL for multi-tenant and real-time workloads" \
      org.label-schema.url="https://www.citusdata.com" \
      org.label-schema.vcs-url="https://github.com/citusdata/citus" \
      org.label-schema.vendor="Citus Data, Inc." \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0"

ENV CITUS_VERSION ${VERSION}.citus-1
# install Citus
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       postgresql-server-dev-$PG_MAJOR make gcc wget libicu-dev \
    && curl -s https://install.citusdata.com/community/deb.sh | bash \
    && apt-get install -y postgresql-$PG_MAJOR-citus-10.2=$CITUS_VERSION \
                          postgresql-$PG_MAJOR-hll=2.16.citus-1 \
                          postgresql-$PG_MAJOR-topn=2.4.0 \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://ja.osdn.net/dl/pgbigm/pg_bigm-1.2-20200228.tar.gz \
    && tar zxf pg_bigm-1.2-20200228.tar.gz \
    && cd pg_bigm-1.2-20200228 && make USE_PGXS=1 && make USE_PGXS=1 install

# add citus/pg_bigm to default PostgreSQL config
RUN echo "shared_preload_libraries='pg_bigm'" >> /usr/share/postgresql/postgresql.conf.sample
RUN echo "shared_preload_libraries='citus'" >> /usr/share/postgresql/postgresql.conf.sample

# add scripts to run after initdb
COPY 001-create-citus-extension.sql /docker-entrypoint-initdb.d/

# add health check script
COPY pg_healthcheck wait-for-manager.sh /
RUN chmod +x /wait-for-manager.sh

# entry point unsets PGPASSWORD, but we need it to connect to workers
# https://github.com/docker-library/postgres/blob/33bccfcaddd0679f55ee1028c012d26cd196537d/12/docker-entrypoint.sh#L303
RUN sed "/unset PGPASSWORD/d" -i /usr/local/bin/docker-entrypoint.sh

HEALTHCHECK --interval=4s --start-period=6s CMD ./pg_healthcheck
