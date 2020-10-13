# scripts for open seamap tile src_tileserver


## build and start container

download compressed osm database  
```
cd src_tileserver_scripts/
mkdir src_tileserver_scripts$ mkdir -p volumes/download
wget -c https://ftp5.gwdg.de/pub/misc/openstreetmap/planet.openstreetmap.org/pbf/planet-latest.osm.pbf     -O volumes/download/planet-latest.osm.pbf
wget -c https://ftp5.gwdg.de/pub/misc/openstreetmap/planet.openstreetmap.org/pbf/planet-latest.osm.pbf.md5 -O volumes/download/planet-latest.osm.pbf.md5
```

build and start container
```
cd src_tileserver_scripts/
./scripts/docker-service.sh build
./scripts/docker-service.sh start
```

## initial import database
```
cd src_tileserver_scripts/
./scripts/docker-service.sh stop
./scripts/docker-service.sh import
```

note: you can check the size of docker volumes wwith following command "docker system df -v"

sample
```
VOLUME NAME                    LINKS               SIZE
openstreetmap-flat             1                   56.47GB
openstreetmap-rendered-tiles   0                   0B
openstreetmap-db               2                   817.9GB
```


## backup
t.b.d

## restore
t.b.d

## prepare first update procedure

### determine latest osmid in database
you need to start and connect to the container first
```
cd src_tileserver_scripts/
./scripts/docker-service.sh start
./scripts/docker-service.sh connect
```

the following sample shows you how to determine latest osmid in database
```
root@osmdbutils:/replication# ./scripts/determine_latest_osmid.sh
    max     
------------
 7058904685
(1 row)
```

### determine initial sequence number for update procedure
```
root@osmdbutils:/replication# ./scripts/whichdiff.pl 7058904685
.
.
.
check http://planet.openstreetmap.org/replication/minute//003/804/437.osc.gz
firstnode 003/804/437.osc.gz = 7058902376
node 7058904685 found in file 003/804/437.osc.gz
therefore, use status file 003/804/427.state.txt:#Mon Dec 16 01:58:03 UTC 2019
sequenceNumber=3804427
txnMaxQueried=2483240379
txnActiveList=
txnReadyList=
txnMax=2483240379
timestamp=2019-12-16T01\:58\:02Z
```

note: the sequence number is 3804427

### create sequence file
```
root@osmdbutils:/replication# mkdir ./work/data/             
root@osmdbutils:/replication# echo 3804427 > ./work/data/sequence_file
```
### start update processes

the following sample shows how to start the update process
```
root@osmdbutils:/replication# service cron start
[ ok ] Starting periodic command scheduler: cron.
```

you can check the procedure with command:
```
root@osmdbutils:/replication# tail -f work/replication.log
```

sample output:
```
root@osmdbutils:/replication# tail -f work/replication.log
[INFO ] 2020-01-07.07:10:01 bgn replication Tue Jan  7 07:10:01 UTC 2020
[INFO ] 2020-01-07.07:10:02 start update: osmosis replication is 31903 minutes behind upstream
[INFO ] 2020-01-07.07:10:02 make backup copy of sequence_file
[INFO ] 2020-01-07.07:10:02 bgn: pyosmium-get-changes sequence=3804427
```
