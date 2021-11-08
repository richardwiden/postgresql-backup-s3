#!/bin/bash

set -e
if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi
LOGFILE=/var/log/backup.log
if [ "${RESTORE}" = "**None**" ]; then
  if [ "${SCHEDULE}" = "**None**" ]; then
    touch /var/log/backup.log
    sh backup.sh >> $LOGFILE
    cat $LOGFILE
  else
    touch /var/log/backup.log
    exec go-cron "$SCHEDULE" /bin/sh backup.sh >> $LOGFILE
  fi
else
  sh restore.sh >> $LOGFILE
  cat $LOGFILE
fi
