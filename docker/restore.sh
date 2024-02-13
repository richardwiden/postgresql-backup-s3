#!/bin/bash
. env.sh

echo "-----" >&1
echo "Restoring1 dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..." >&1

if [ "${RESTORE}" = "**None**" ]; then
  echo "Restore not set" >&1
  exit 40
elif [ "${RESTORE}" = "latest" ]; then
  echo "Restoring2 LATEST." >&1
  S3_COMMAND="${AWS_ARGS} s3api list-objects-v2 --bucket ${S3_BUCKET} --prefix ${S3_PREFIX} --query reverse(sort_by(Contents||*[],&LastModified))[0].Key"

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
  if [ ! -s /tmp/output ]; then
    echo "No output from AWS" >&2
    exit 44
  fi
  RESTORE="$(cut -d '/' -f2 /tmp/output  | cut -d '"' -f1)"
  echo "Restoring3 latest: ${RESTORE}"
  SRC_FILE=${RESTORE}
else
  echo "Restoring4 file: $RESTORE"
  SRC_FILE=${RESTORE}
fi

DEST_FILE=${SRC_FILE}
aws ${AWS_ARGS} s3 cp "s3://${S3_BUCKET}/${S3_PREFIX}/${SRC_FILE}" "${DEST_FILE}"

if [ "${ENCRYPTION_PASSWORD}" = "**None**" ]; then
  echo "File not encrypted"
else
  DEST_FILE="restore.sql.gz"
  openssl aes-256-cbc -iter 1000 -d -in "${SRC_FILE}" -out "${DEST_FILE}" -k "${ENCRYPTION_PASSWORD}" || exit 46
  rm "${SRC_FILE}"
  SRC_FILE=${DEST_FILE}
fi

if [ "${POSTGRES_DATABASE}" == "all" ]; then
  echo "Can't restore all" >&2
  exit 47
else
  if [ ! -f "$SRC_FILE" ]; then
    echo "No file to restore from" >&2
        exit 48
  fi
  echo "Restoring5 pg_restore ${POSTGRES_HOST_OPTS} -d ${POSTGRES_DATABASE}  --no-owner --no-privileges ${SRC_FILE}" >&1
  pg_restore ${POSTGRES_HOST_OPTS} -d ${POSTGRES_DATABASE}  --no-owner --no-privileges $SRC_FILE
fi


echo "----- SQL restore finished" >&1
exit 0
