#!/bin/bash

# Tcp dump collection and dhcp state monitoring
# Version 1.0

# InitVars
G_DAY="$(date '+%Y.%m.%d')"
G_LOG_DIR="${HOME}/log/netmon"
G_LOG_FILE="${G_LOG_DIR}/netmon_log.$(hostname).${G_DAY}"
G_TIMEOUT=5
G_INTEFACES="eth0 docker0"
G_KILLPIDS=""

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
    log "--- datetime : $(date '+%Y-%m-%dT%H:%M:%S:%N') ---"
    eval "$*" 2>>${G_LOG_FILE} 1>>${G_LOG_FILE}
    log "--- datetime : $(date '+%Y-%m-%dT%H:%M:%S:%N') ---"
    log "Completed $* \nRes code: $?\n"
}

function cat_to_log()
{
    log "\n=== BEGIN_FILE : ${1} ==="
    /bin/cat "${1}" >> ${G_LOG_FILE}
    log "=== END FILE : ${1} ===\n"
}

# MAIN

log "\n\n\n=== START $0 at $(date '+%Y-%m-%dT%H:%M:%S')\n"

CUR_TIME_IN_SECONDS="$(date +%s)"
TIME_TO_EXIT=$(expr $CUR_TIME_IN_SECONDS + $G_TIMEOUT)

for INTERFACE in $G_INTEFACES
do
    echo "IVAN $INTERFACE"
    echo "/usr/sbin/tcpdump -i $INTERFACE -n -vvv -w ${G_LOG_DIR}/raw_tcpdump.${INTERFACE}"
    /usr/sbin/tcpdump -i "$INTERFACE" -n -vvv -w "${G_LOG_DIR}/raw_tcpdump.${INTERFACE}" 2>>/dev/null 1>>/dev/null &
    L_PID=$!
    G_KILLPIDS="$G_KILLPIDS $PID"
done

log "Collecting netstat information..."
for OPTION in -ae -le -pe -oe -Fe -Ce -se
do 
    run_cmd /bin/netstat ${OPTION}
done
log "Collecting netstat information...DONE\n"
    
    
log "Collecting an interfaces statistics..." 
run_cmd ifconfig -a
for IFACE in eth0 eth1 eth2 eth3 eth4
do
    run_cmd ethtool -S ${IFACE}
done
log "Collecting interfaces statistics...DONE\n"

log "Collecting sockets information..."
for S_FILE in $(find /proc/net/ -type f)
do
    cat_to_log ${S_FILE}
done
log "Collecting sockets information...DONE\n"

while [ $CUR_TIME_IN_SECONDS -lt $TIME_TO_EXIT ]; do
    run_cmd 'ps aux |grep dhcpd' 
    
    sleep 1
    CUR_TIME_IN_SECONDS="$(date +%s)"
done

for PID in $G_KILLPIDS
do
    run_cmd kill $PID
done

log "=== END $0  at $(date '+%Y-%m-%dT%H:%M:%S')\n"
