#!/bin/bash
set -e
set -o pipefail
. env.sh

#Unable to check for script running due to subcommands [ $(pgrep -fl backup.sh | wc -l) -gt 1 ] ;
if \
  [ $(pgrep aws | wc -l) -gt 0 ] || \
  [ $(pgrep pg_dumpall | wc -l) -gt 0 ] || \
  [ $(pgrep pg_dump | wc -l) -gt 0 ] || \
  [ $(pgrep openssl | wc -l) -gt 0 ] || \
  [ $(pgrep gzip | wc -l) -gt 0 ]
then
  echo "Another backup is running"
  exit 33
fi

echo "-----"
echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

SRC_FILE=${POSTGRES_DATABASE}_$(date +"%Y%m%dT%H%M%SZ").sql.gz
DEST_FILE=$SRC_FILE

if [ "${POSTGRES_DATABASE}" == "all" ];
then
  pg_dumpall $POSTGRES_HOST_OPTS | gzip > $SRC_FILE
else
  echo "pg_dump $POSTGRES_HOST_OPTS -C -w --format=c --blobs --no-owner --no-privileges --no-acl $POSTGRES_DATABASE > $SRC_FILE"
  pg_dump $POSTGRES_HOST_OPTS -C -w --format=c --blobs --no-owner --no-privileges --no-acl $POSTGRES_DATABASE > $SRC_FILE
fi


if [ "${ENCRYPTION_PASSWORD}" = "**None**" ];
then
  echo "Not encrypted"
else
  echo "Encrypting ${SRC_FILE}"
  DEST_FILE="$SRC_FILE.enc"
  openssl enc -aes-256-cbc -iter 1000 -in "$SRC_FILE" -out "${DEST_FILE}" -k "$ENCRYPTION_PASSWORD"
  rm "$SRC_FILE" #Delete unencrypted file in local file system
  SRC_FILE=$DEST_FILE

fi

S3_COMMAND="$AWS_ARGS s3 cp $SRC_FILE s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE"
echo "Uploading dump to $S3_COMMAND"

aws $S3_COMMAND || exit 2


if [ "${ENCRYPTION_PASSWORD}" = "**None**" ];
then
  echo "Not encrypting latest backup"
  LATEST_BACKUP=latest.gz
else
  echo "Not encrypting latest backup"
  LATEST_BACKUP=latest.gz.enc
fi
rm "$LATEST_BACKUP" 2>/dev/null > /dev/null || true
rm "$LATEST_BACKUP.enc" 2>/dev/null > /dev/null || true
mv "$SRC_FILE" "$LATEST_BACKUP" #Save last backup in internal file system

echo "Handling old files"
if [ "${DELETE_OLDER_THAN}" = "**None**" ]; then
  echo "Not deleting old backups"
else
  echo "Checking for files older than ${DELETE_OLDER_THAN}"
  older_than=$(date -d "${DELETE_OLDER_THAN}" +%Y-%m-%dT%H:%M:%S.%3NZ)
  echo "older_than: $older_than"
  S3_COMMAND="$AWS_ARGS s3api list-objects --bucket $S3_BUCKET --prefix $S3_PREFIX --query \"Contents[?LastModified<='$older_than'].Key\" --output=json"
  # shellcheck disable=SC2086
  echo "aws $S3_COMMAND"
  RESULT=$(aws $S3_COMMAND)
  echo "RESULT: $RESULT"
  echo $RESULT | jq -r '.[]' | while read -r line
  do
    echo "Deleting $line"
    aws $AWS_ARGS s3 rm "s3://$S3_BUCKET/$S3_PREFIX/$fileName"
  done;
fi

echo "SQL backup finished"
echo "-----"
