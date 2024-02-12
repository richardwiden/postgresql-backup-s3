#!/bin/bash
set -e
set -o pipefail
. env.sh

function runCommand()
{
  local command=$1
  eval "$command" 2>/tmp/error > /tmp/output
  return $?
}

echo "-----" >&1
echo "Restoring dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..." >&1

if [ "${RESTORE}" = "**None**" ]; then
  echo "Restore not set"
  exit 40
elif [ "${RESTORE}" = "latest" ]; then
  echo "Restoring LATEST." >&1
  S3_COMMAND="$AWS_ARGS s3 ls s3://${S3_BUCKET}/${S3_PREFIX}/"
  # shellcheck disable=SC2089
  S3_COMMAND="$S3 "
  #UPLOAD=$(aws $S3_COMMAND --output json)
  #aws $S3 s3api list-objects-v2 --bucket $S3_BUCKET --prefix sql --query 'reverse(sort_by(Contents || *[], &LastModified))[0].Key'
  touch /tmp/output || true
  touch /tmp/error || true
  if [ ! -f /tmp/output ];  then echo "Error creating temp output file" >&2; exit 41; fi
  if [ ! -f /tmp/error ];   then echo "Error creating temp err file"    >&2; exit 42; fi
  echo "Running AWS" >&1
  if [ $(($(runCommand "aws $AWS_ARGS s3api list-objects-v2 --bucket $S3_BUCKET --prefix $S3_PREFIX --query 'reverse(sort_by(Contents || *[], &LastModified))[0].Key'"))) -eq 0 ]
  then
    echo "AWS done" >&1
  else
    echo "AWS fail" >&2
  fi
  if [ -s /tmp/error ]; then
      echo "Error getting latest backup from S3" >&2
      LOGIN_ERROR_COUNT=$(grep -c 'An error occurred (SignatureDoesNotMatch)'  /tmp/error)
      if [ "$LOGIN_ERROR_COUNT" -ge "1" ]; then
        echo "Found expected LoginError" >&1
        exit 0
      else
        echo "Error: Unknown error"  >&2
        cat /tmp/error >&2
        exit 43
      fi
  fi
  if [ ! -s /tmp/output ]; then
    echo "No output from AWS" >&2
    exit 44
  fi
  echo "Output from AWS ---- " >&1
  cat /tmp/output >&1
  echo "Output from AWS ---- " >&1


  RESTORE="$(cut -d '/' -f2 /tmp/output  | cut -d '"' -f1)"
  echo "Restoring latest: ${RESTORE}"
  SRC_FILE=${RESTORE}
else
  echo "Restoring file: $RESTORE"
  SRC_FILE=${RESTORE}
fi

DEST_FILE=${SRC_FILE}

# shellcheck disable=SC2086
echo "aws $AWS_ARGS s3 cp s3://$S3_BUCKET/$S3_PREFIX/$SRC_FILE $DEST_FILE"
aws $AWS_ARGS s3 cp s3://$S3_BUCKET/$S3_PREFIX/$SRC_FILE $DEST_FILE  || exit 45
if [ "${ENCRYPTION_PASSWORD}" = "**None**" ]; then
  echo "File not encrypted"
else
  DEST_FILE="restore.sql.gz"
  openssl aes-256-cbc -iter 1000 -d -in "$SRC_FILE" -out $DEST_FILE -k "$ENCRYPTION_PASSWORD" || exit 46
  rm "$SRC_FILE"
  SRC_FILE=$DEST_FILE
fi

if [ "${POSTGRES_DATABASE}" == "all" ]; then
  echo "Can't restore all" >&2
  exit 47
else
  if [ ! -f "$SRC_FILE" ]; then
    echo "No file to restore from" >&2
        exit 48
  fi
  echo "Restoring pg_restore ${POSTGRES_HOST_OPTS} -d ${POSTGRES_DATABASE}  --no-owner --no-privileges ${SRC_FILE}" >&1
  pg_restore ${POSTGRES_HOST_OPTS} -d ${POSTGRES_DATABASE}  --no-owner --no-privileges $SRC_FILE
fi


echo "SQL restore finished" >&1
echo "-----" >&1
exit 0
