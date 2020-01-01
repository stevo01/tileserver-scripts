FROM debian:10

# Based on
# giggls/tileserver-scripts
# https://github.com/giggls/tileserver-scripts

# Install dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    python3 \
    python3-pip \
    python3-setuptools \
    python-pip \
    cron \
    wget \
    curl \
    npm \
    git \
    procps \
    nano mc psmisc \
    postgresql-client \
    osm2pgsql  \
    python3-pyosmium \
    osmium-tool \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/lib/python3-pyosmium/pyosmium-get-changes /usr/local/bin/pyosmium-get-changes

RUN pip install pyYAML


# Configure stylesheet
RUN mkdir -p /replication/src
WORKDIR /replication/src
RUN git clone https://github.com/gravitystorm/openstreetmap-carto.git \
 && git -C openstreetmap-carto checkout v4.23.0
WORKDIR /replication/src/openstreetmap-carto
USER root
RUN npm install -g carto@0.18.2
RUN carto project.mml > mapnik.xml
WORKDIR /replication


# deploy scripts and config files
USER root
RUN mkdir -p /replication/scripts
COPY run.sh /replication/scripts
COPY whichdiff.pl /replication/scripts
COPY replicate-loop.sh /replication/scripts
COPY determine_latest_osmid.sh /replication/scripts
COPY initial-import.sh /replication/scripts


RUN chmod +x /replication/scripts/*.sh \
&& chmod +x /replication/scripts/*.pl \
&& chown root:root /replication/scripts/*.sh \
&& chown root:root /replication/scripts/*.pl

RUN echo "*/5 * * * *   root    /replication/scripts/replicate-loop.sh\n" >> /etc/crontab

# Start running
ENTRYPOINT ["/replication/scripts/run.sh"]
CMD []
