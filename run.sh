#!/bin/bash

#set -e

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi
LOGFILE=/var/log/backup.log
mkdir -p /var/log
touch $LOGFILE
echo "Run" > $LOGFILE

cat $LOGFILE
if [ "${RESTORE}" = "**None**" ]; then
  if [ "${SCHEDULE}" = "**None**" ]; then
    sh backup.sh >> $LOGFILE 2>&1
    cat $LOGFILE
  else
      exec go-cron "$SCHEDULE" /bin/sh backup.sh >> $LOGFILE 2>&1
  fi
else
  echo "Restoring"
  sh restore.sh >> $LOGFILE 2>&1
  cat $LOGFILE
fi
