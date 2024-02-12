#!/bin/bash

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

echo "" > "${LOG}"
echo "" > "${ERR}"

if [ "${RESTORE}" != "**None**" ]; then
  if [ $(bash restore.sh 2>>"${ERR}" 1>>"${LOG}") != 0 ];
  then
    echo "Error from restore.sh: $?"
    exit $?
  fi
  exit 0
fi

if [ "${SCHEDULE}" = "**None**" ]; then
  if [ $(bash backup.sh 2>>"${ERR}" 1>>"${LOG}") != 0 ];
  then
    echo "Error from backup.sh during backup: $?"
    exit $?
  fi
  exit 0
fi


if [ $(exec go-cron "$SCHEDULE" /bin/bash -c "./backup.sh 2>>${ERR} 1>>${LOG}") != 0 ];
then
  echo "Error from backup.sh during scheduled backup: $?"
  exit $?
fi
exit 0
