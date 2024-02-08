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

echo "-----"
echo "Restoring dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

if [ "${RESTORE}" = "**None**" ]; then
  echo "Restore not set"
  exit 2
elif [ "${RESTORE}" = "latest" ]; then
  echo "Restoring LATEST."
  S3_COMMAND="$AWS_ARGS s3 ls s3://${S3_BUCKET}/${S3_PREFIX}/"
  # shellcheck disable=SC2089
  S3_COMMAND="$S3 "
  #UPLOAD=$(aws $S3_COMMAND --output json)
  #aws $S3 s3api list-objects-v2 --bucket $S3_BUCKET --prefix sql --query 'reverse(sort_by(Contents || *[], &LastModified))[0].Key'
  touch /tmp/output || true
  touch /tmp/error || true
  if [ ! -f /tmp/output ]; then echo "Error creating temp output file"; exit 4; fi
  if [ ! -f /tmp/error ]; then  echo "Error creating temp err file"; exit 5; fi
  echo "Running AWS"
  if [ $(($(runCommand "aws $AWS_ARGS s3api list-objects-v2 --bucket $S3_BUCKET --prefix $S3_PREFIX --query 'reverse(sort_by(Contents || *[], &LastModified))[0].Key'"))) -eq 0 ]
  then
    echo "AWS done";
  else
    echo "AWS fail"
  fi
  if [ -s /tmp/error ]; then
      echo "Error getting latest backup from S3"
      cat /tmp/error
      LOGIN_ERROR_COUNT=$(cat /tmp/error | grep -c 'An error occurred (SignatureDoesNotMatch) when calling the ListObjectsV2 operation: The request signature we calculated does not match the signature you provided. Check your key and signing method.')
      if [ "$LOGIN_ERROR_COUNT" -eq "1" ]; then
        echo "Error: SignatureDoesNotMatch. Check your key and signing method."
        exit 0
      else
        echo "Error: Unknown error"
        cat /tmp/error
        exit 3
      fi
  fi
  if [ ! -s /tmp/output ]; then
    echo "No output from AWS"
    cat /tmp/error
    exit 3
  fi
  echo "Output from AWS ---- "
  cat /tmp/output
  echo "Output from AWS ---- "


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
aws $AWS_ARGS s3 cp s3://$S3_BUCKET/$S3_PREFIX/$SRC_FILE $DEST_FILE  || exit 2
if [ "${ENCRYPTION_PASSWORD}" = "**None**" ]; then
  echo "File not encrypted"
else
  DEST_FILE="restore.sql.gz"
  openssl aes-256-cbc -iter 1000 -d -in "$SRC_FILE" -out $DEST_FILE -k "$ENCRYPTION_PASSWORD" || exit 2
  rm "$SRC_FILE"
  SRC_FILE=$DEST_FILE
fi

if [ "${POSTGRES_DATABASE}" == "all" ]; then
  echo "Can't restore all"
  exit 2
else
  if [ -f "$SRC_FILE" ]; then
    echo "Restoring pg_restore $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE  --no-owner --no-privileges $SRC_FILE 2>&1"
    # shellcheck disable=SC2086
    pg_restore $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE  --no-owner --no-privileges $SRC_FILE || exit 2
  else
    echo "No file to restore from"; exit 2;
  fi
fi


echo "SQL restore finished"
echo "-----"
exit 0
