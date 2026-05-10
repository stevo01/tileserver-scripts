FROM debian:13

ENV DEBIAN_FRONTEND=noninteractive
# deps
RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates curl wget git procps nano mc psmisc cron \
    pigz \
    python3 python3-pip python3-setuptools python3-dev \
    postgresql-client \
    python3-pyosmium osmium-tool \
    libipc-sharelite-perl libjson-perl libgd-perl libwww-perl \
    build-essential cmake g++ libboost-dev libboost-system-dev \
    libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev \
    libpq-dev libproj-dev lua5.3 liblua5.3-dev \
    npm nodejs \
    pandoc 

RUN apt-get update && apt-get install --no-install-recommends -y \
       python3-wheel python3-psycopg2 python3-yaml \
       osm2pgsql node-carto iputils-ping gdal-bin unzip

WORKDIR /replication/src
RUN git clone https://github.com/gravitystorm/openstreetmap-carto \
    && cd openstreetmap-carto \
    && git pull --all \
    && git switch --detach v5.9.0 \
    && carto -v

WORKDIR   /replication/src/openstreetmap-carto 
RUN carto /replication/src/openstreetmap-carto/project.mml > /replication/src/openstreetmap-carto/mapnik.xml


# scripts + timer
WORKDIR /replication
RUN mkdir -p /replication/scripts
COPY run.sh /replication/scripts/
COPY whichdiff.pl replicate-loop.sh replicate-db.sh determine_latest_osmid.sh \
     initial-import.sh create_indexes.sh create_backup.sh /replication/scripts/
COPY osm-replicate.service /etc/systemd/system
COPY osm-replicate.timer   /etc/systemd/system

RUN chmod +x /replication/scripts/*.sh /replication/scripts/*.pl && \
    chown root:root /replication/scripts/*

# cron
RUN printf "*/5 * * * *   root    /replication/scripts/replicate-db.sh\n" >> /etc/crontab

ENTRYPOINT ["/replication/scripts/run.sh"]
CMD []
