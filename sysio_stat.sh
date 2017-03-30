#!/bin/bash

# Collect common system status and NFS shares using
# Version 1.0

# InitVars
G_DAY="$(date '+%Y.%m.%d')"
G_LOG_DIR="${HOME}/logs/sysio_stat"
G_LOG_FILE="${G_LOG_DIR}/sysio_stat_log.$(hostname).${G_DAY}"

if [ "${1}" == "" ]
then
    G_TIMEOUT=300
else
    G_TIMEOUT="${1}"
fi

if [ "${2}" == "" ]
then
    G_SLEEP_TIME=1
else
    G_SLEEP_TIME="${2}"
fi

# Preliminaries
[ -d "${G_LOG_DIR}" ] || mkdir -p "${G_LOG_DIR}"
[ -f "${G_LOG_FILE}" ] || touch "${G_LOG_FILE}"

function log()
{
    echo -e "${1}" 2>>${G_LOG_FILE} 1>>${G_LOG_FILE}
}

function log_error()
{
    log "\n\t!!!!! ERROR : $* !!!!!\n"
}

function run_cmd()
{
    log "\nRunning $* ... "
    log "\t--- datetime : $(date '+%Y-%m-%dT%H:%M:%S:%N') ---"
    eval "$*" 2>>${G_LOG_FILE} 1>>${G_LOG_FILE}
    L_RC=$?
    log "\t--- datetime : $(date '+%Y-%m-%dT%H:%M:%S:%N') ---"
    log "Completed $* \nRes code: $L_RC\n"
}

function cat_to_log()
{
    log "\n=== BEGIN_FILE : ${1} ==="
    /bin/cat "${1}" >> ${G_LOG_FILE}
    log "=== END FILE : ${1} ===\n"
}

# MAIN
echo -e "\nStarting info collection ..."
log "\n\n\n=== START $0 at $(date '+%Y-%m-%dT%H:%M:%S')\n"

CUR_TIME_IN_SECONDS="$(date +%s)"
TIME_TO_EXIT=$(expr $CUR_TIME_IN_SECONDS + $G_TIMEOUT)

while [ ${CUR_TIME_IN_SECONDS} -lt ${TIME_TO_EXIT} ]; do
    run_cmd vmstat 
    run_cmd vmstat -a 
    run_cmd vmstat -d 
    run_cmd vmstat -D 
    run_cmd vmstat -s 
    run_cmd vmstat -m 
    
    run_cmd netstat -an
    run_cmd showmount -a
    run_cmd showmount -e
    
    run_cmd nfsiostat -as
    run_cmd nfsiostat -ds
    run_cmd nfsiostat -ps
    run_cmd nfsstat -v
    
    run_cmd top -n 5
    run_cmd ps aux
    
    run_cmd free
    cat_to_log /proc/meminfo
    
    echo -n "."
    sleep ${G_SLEEP_TIME}
    CUR_TIME_IN_SECONDS="$(date +%s)"
done

log "=== END $0  at $(date '+%Y-%m-%dT%H:%M:%S')\n"
echo -e "\nDone"
