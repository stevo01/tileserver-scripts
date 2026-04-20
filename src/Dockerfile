FROM debian:12

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
       python3-wheel python3-psycopg2 python3-yaml 

#RUN rm -rf /var/lib/apt/lists/*

# Python libs
# RUN pip3 install --no-cache-dir wheel psycopg2 pyyaml

# build osm2pgsql
RUN mkdir -p /replication/src
WORKDIR /replication/src
RUN git clone https://github.com/openstreetmap/osm2pgsql && \
    cd osm2pgsql && \
    git checkout 1.5.0 && \
    mkdir build && cd build && \
    cmake .. && make -j"$(nproc)" && make install

# stylesheet
WORKDIR /replication/src
RUN git clone https://github.com/gravitystorm/openstreetmap-carto.git && \
    git -C openstreetmap-carto checkout v4.23.0
WORKDIR /replication/src/openstreetmap-carto
RUN npm install -g carto@0.18.2 && \
    carto project.mml > /replication/src/openstreetmap-carto/mapnik.xml

# scripts + timer
WORKDIR /replication
RUN mkdir -p /replication/scripts
COPY run.sh /replication/scripts/
COPY whichdiff.pl replicate-loop.sh replicate-db.sh determine_latest_osmid.sh \
     initial-import.sh create_indexes.sh update_indexes.sh create_backup.sh /replication/scripts/
COPY osm-replicate.service /etc/systemd/system
COPY osm-replicate.timer   /etc/systemd/system

RUN chmod +x /replication/scripts/*.sh /replication/scripts/*.pl && \
    chown root:root /replication/scripts/*

# cron
RUN printf "*/5 * * * *   root    /replication/scripts/replicate-db.sh\n" >> /etc/crontab

ENTRYPOINT ["/replication/scripts/run.sh"]
CMD []
