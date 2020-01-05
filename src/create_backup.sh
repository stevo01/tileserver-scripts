#!/bin/bash
set -x
LOGFILE=/replication/work/backup.log

function log_info {
    today=`date +%Y-%m-%d.%H:%M:%S`
    echo "[INFO ] $today $1" 2>&1 | tee -a $LOGFILE
}

function log_error {
    today=`date +%Y-%m-%d.%H:%M:%S`
    echo "[ERROR] $today $1" 2>&1 | tee -a $LOGFILE
    exit 1
}


log_info "bgn backup for following directories:"
du -sh /var/lib/postgresql/11/main/ 2>&1 | tee -a $LOGFILE
du -sh /nodes/  2>&1 | tee -a $LOGFILE
time tar -I pigz -cf /backup/openstreetmap-flat-nodes.tgz /nodes/ 2>&1 | tee -a $LOGFILE
time tar -I pigz -cf /backup/openstreetmap-data-planet-latest.tgz /var/lib/postgresql/11/main/ 2>&1 | tee -a $LOGFILE
log_info "archives created:"
ls /backup/openstreetmap-flat-nodes.tgz -lh 2>&1 | tee -a $LOGFILE
ls /backup/openstreetmap-data-planet-latest.tgz -lh 2>&1 | tee -a $LOGFILE
log_info "end backup"
