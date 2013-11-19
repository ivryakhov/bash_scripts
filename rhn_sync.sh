#!/bin/bash

# The script for mirroring Red Hat repositories to local filesystem
# Version: 1.01

#--Init-Vars----------
G_REPO_HOME="/home/ivan/rhn_mirror" # Filesystem directory where repositories will be placed
G_LOG_DIR="${G_REPO_HOME}/logs"     # Filesystem directory for logs
G_DATE="$(date '+%Y.%m.%d_%H%M')"   # Current date
G_LOG_FILE="${G_LOG_DIR}/rhn_mirror_log.${G_DATE}"  # Log file name

# List of Red Hat repositories to be cloned. It is needed to subscrube on this channels 
# with help of rhn-channel tool or web-interface on redhat.com before using this script.
G_REPOS_LIST="jbappplatform-6-x86_64-server-6-rpm rhel-x86_64-rhev-mgmt-agent-6 rhel-x86_64-server-6 rhel-x86_64-server-6-rhevh rhel-x86_64-server-6-rhevm-3.1 rhel-x86_64-server-supplementary-6 rhel-x86_64-server-v2vwin-6 rhel-x86_64-server-6-rhevm-3 jbappplatform-5-x86_64-server-6-rpm"

#--Preliminaries------
[ -d "${G_REPO_HOME}" ] || mkdir -p "${G_REPO_HOME}" >> "${G_LOG_FILE}" 2>&1
[ -d "${G_LOG_DIR}" ] || mkdir -p "${G_LOG_DIR}" >> "${G_LOG_FILE}" 2>&1
[ -f "${G_LOG_FILE}" ] || touch "${G_LOG_FILE}" >> "${G_LOG_FILE}" 2>&1

echo "Removing old log files..." >> "${G_LOG_FILE}"
find "${G_LOG_DIR}" -ctime +30 -exec rm -f {} \; >> "${G_LOG_FILE}" 2>&1

#--Main--------------
echo -e "Starting $0 at ${G_DATE}\n" >> "${G_LOG_FILE}"

G_RES_MESSAGE="\n\nResult:\n"
G_GEN_RES="OK"

for L_REPO in ${G_REPOS_LIST}
do
    L_TRYS=0
    L_RES=1
    while [ $L_TRYS -lt 3 ]
    do
        echo -e "Cloning the ${L_REPO} repository...\n" >> "${G_LOG_FILE}"
	/usr/bin/reposync -p "${G_REPO_HOME}" --repoid=${L_REPO} -l >> "${G_LOG_FILE}" 2>&1
        L_SYNC_RES=$?
        if [ ${L_SYNC_RES} -eq 0 ] 
        then
            L_TRYS=4
            L_RES=0
            echo -e "Cloning the ${L_REPO} repository has been successfully completed\n" >> "${G_LOG_FILE}"
        else
            echo -e "Cloning the ${L_REPO} repository was failed. Retrying...\n" >> "${G_LOG_FILE}"
            L_TRYS=`expr $L_TRYS + 1`
        fi
    done

    if [ $L_RES -eq 0 ]
    then
        L_CLON_RES="OK"
    else
        L_CLON_RES="NOK"
        G_GEN_RES="NOK"
    fi
    G_RES_MESSAGE="${G_RES_MESSAGE}Cloning the ${L_REPO} repository: ${L_CLON_RES}\n"
done

echo -e "\nCreating or updating repository..." >> "${G_LOG_FILE}"
/usr/bin/createrepo "${G_REPO_HOME}" >> "${G_LOG_FILE}" 2>&1
[ $? -ne 0 ] && L_CR_RES="NOK" && G_GEN_RES="NOK" || L_CR_RES="OK"
echo -e "Creating or updating repository...${L_CR_RES}" >> "${G_LOG_FILE}"

G_RES_MESSAGE="${G_RES_MESSAGE}\nCommon result: ${G_GEN_RES}"

echo -e "${G_RES_MESSAGE}" >> "${G_LOG_FILE}"
