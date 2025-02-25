#!/bin/bash

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

echo "" > "${LOG}"
echo "" > "${ERR}"

if [ "${RESTORE}" != "**None**" ]; then
  bash restore.sh 2>>"${ERR}" 1>>"${LOG}"
  ERROR=$?
  if [ ${ERROR} != 0 ]
  then
    echo "Error from restore.sh: ${ERROR}"
    exit ${ERROR}
  fi
  exit 0
fi

if [ "${SCHEDULE}" = "**None**" ]; then
  bash backup.sh 2>>"${ERR}" 1>>"${LOG}"
  ERROR=$?
  if [ ${ERROR} != 0 ]
  then
    echo "Error from backup.sh during backup: ${ERROR}"
    exit ${ERROR}
  fi
  exit 0
fi

exec go-cron "$SCHEDULE" /bin/bash -c "./backup.sh 2>>${ERR} 1>>${LOG}"
ERROR=$?
if [ ${ERROR} != 0 ]
then
  echo "Error from go-cron: ${ERROR}"
  exit ${ERROR}
fi
exit 0
