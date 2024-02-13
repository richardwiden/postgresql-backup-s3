#!/bin/bash
. env.sh

#Unable to check for script running due to subcommands [ $(pgrep -fl backup.sh | wc -l) -gt 1 ] ;
if \
  [ $(pgrep aws | wc -l) -gt 0 ] || \
  [ $(pgrep pg_dumpall | wc -l) -gt 0 ] || \
  [ $(pgrep pg_dump | wc -l) -gt 0 ] || \
  [ $(pgrep openssl | wc -l) -gt 0 ] || \
  [ $(pgrep gzip | wc -l) -gt 0 ]
then
  date
  echo "Another backup is running" >&2
  exit 33
fi

echo "----- SQL backup start" >&1

SRC_FILE=${POSTGRES_DATABASE}_$(date +"%Y%m%dT%H%M%SZ").sql.gz
DEST_FILE=${SRC_FILE}

if [ "${POSTGRES_DATABASE}" == "all" ];
then
  pg_dumpall ${POSTGRES_HOST_OPTS} | gzip > "${SRC_FILE}" >&1  || exit 32
else
  pg_dump ${POSTGRES_HOST_OPTS} -C -w --format=c --blobs --no-owner --no-privileges --no-acl "${POSTGRES_DATABASE}" > "${SRC_FILE}"  || exit 30
fi


if [ "${ENCRYPTION_PASSWORD}" = "**None**" ];
then
  echo "Not encrypted" >&1
else
  DEST_FILE="$SRC_FILE.enc"
  openssl enc -aes-256-cbc -iter 1000 -in "${SRC_FILE}" -out "${DEST_FILE}" -k "${ENCRYPTION_PASSWORD}"  || exit 31
  rm "${SRC_FILE}" #Delete unencrypted file in local file system
  SRC_FILE=${DEST_FILE}
fi

S3_COMMAND="$AWS_ARGS s3 cp $SRC_FILE s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE"
aws ${S3_COMMAND}


if [ "${ENCRYPTION_PASSWORD}" = "**None**" ];
then
  mv -f "$SRC_FILE" "latest.gz"
else
  mv -f "$SRC_FILE" "latest.gz.enc"
fi


if [ "${DELETE_OLDER_THAN}" = "**None**" ]
then
  echo "Not deleting old backups"
else
  echo "Checking for files older than ${DELETE_OLDER_THAN}"
  older_than=$(date -d "${DELETE_OLDER_THAN}" +%Y-%m-%dT%H:%M:%S.%3NZ)
  QUERY="(Contents[?LastModified<='$older_than'].Key|[])"
  S3_COMMAND="${AWS_ARGS} s3api list-objects --bucket ${S3_BUCKET} --prefix ${S3_PREFIX} --query ${QUERY} --output=json"

  createTempFile /tmp/output
  createTempFile /tmp/error
  aws ${S3_COMMAND} 2>/tmp/error > /tmp/output || ERROR=$? true
  if [ -s /tmp/error ]; then
      LOGIN_ERROR_COUNT=$(grep -c 'An error occurred (SignatureDoesNotMatch)'  /tmp/error)
      if [ "${LOGIN_ERROR_COUNT}" -ge "1" ]; then
        echo "Login Error" >&1
        exit 34
      else
        echo "Error: Unknown error"  >&2
        cat /tmp/error >&2
        exit ${ERROR}
      fi
  fi
  if [ ! -s /tmp/output ];
  then
    echo "Error: No output from AWS" >&2
    exit 44
  fi
  DELETED=NO
  cat /tmp/output | jq -r '.[]?' | while read -r KEY
  do
    DELETED=YES
    S3_COMMAND="${AWS_ARGS} s3 rm s3://${S3_BUCKET}/${KEY}" #key has prefix as part of it
    aws ${S3_COMMAND} 2>/tmp/error || ERROR=$? true
    if [ -s /tmp/error ]
    then
      echo "Error: Unknown error"  >&2
      cat /tmp/error >&2
      exit ${ERROR}
    fi
    echo "Deleted one old backup: ${KEY}" >&1
  done;

  if [ "${DELETED}" = "YES" ]
  then
    echo "Deleted old backups" >&1
    aws $S3_COMMAND > /tmp/output
  fi
fi

echo "----- SQL backup finished" >&1
exit 0
