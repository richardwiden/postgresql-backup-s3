#!/bin/bash
set -e
set -o pipefail
. env.sh

echo "-----"
echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

SRC_FILE=${POSTGRES_DATABASE}_$(date +"%Y%m%dT%H%M%SZ").sql.gz
DEST_FILE=$SRC_FILE

if [ "${POSTGRES_DATABASE}" == "all" ]; then
  pg_dumpall $POSTGRES_HOST_OPTS | gzip > $SRC_FILE
else
  echo "pg_dump $POSTGRES_HOST_OPTS -C -w --format=c --blobs --no-owner --no-privileges --no-acl $POSTGRES_DATABASE > $SRC_FILE"
  pg_dump $POSTGRES_HOST_OPTS -C -w --format=c --blobs --no-owner --no-privileges --no-acl $POSTGRES_DATABASE > $SRC_FILE
fi


if [ "${ENCRYPTION_PASSWORD}" = "**None**" ]; then
  echo "Not encrypted"
else
  echo "Encrypting ${SRC_FILE}"
  DEST_FILE="$SRC_FILE.enc"
  openssl enc -aes-256-cbc -iter 1000 -in "$SRC_FILE" -out "${DEST_FILE}" -k "$ENCRYPTION_PASSWORD"
  rm "$SRC_FILE" #Delete unencrypted file in local file system
  SRC_FILE=$DEST_FILE

fi

echo "Uploading dump to $AWS_ARGS s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE"

 # shellcheck disable=SC2086
aws $AWS_ARGS s3 cp $SRC_FILE "s3://$S3_BUCKET/$S3_PREFIX/" || exit 2
rm "$SRC_FILE" #Delete file in local file system

if [ "${DELETE_OLDER_THAN}" = "**None**" ]; then
  echo "Not deleting old backups"
else
  echo "Checking for files older than ${DELETE_OLDER_THAN}"
  older_than=$(date -d "$DELETE_OLDER_THAN" +%s)
  # shellcheck disable=SC2086
  aws $AWS_ARGS s3 ls "s3://$S3_BUCKET/$S3_PREFIX/" | grep " PRE " -v | while read -r line;
    do
      fileName=$(echo $line| tr -s ' '| cut -d ' ' -f4)
      created=`echo $line|awk {'print $1" "$2'}`
      created=`date -d "$created" +%s`

      if [ $created -lt $older_than ]
        then
          if [ $fileName != "" ]
            then
              echo "DELETING ${fileName}"
              # shellcheck disable=SC2086
              aws $AWS_ARGS s3 rm s3://$S3_BUCKET/$S3_PREFIX/$fileName
          fi
      else
          echo "${fileName} not older than ${DELETE_OLDER_THAN}"
      fi
    done;
fi

echo "SQL backup finished"
echo "-----"