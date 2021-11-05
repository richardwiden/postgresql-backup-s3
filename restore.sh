#! /bin/sh

set -e
set -o pipefail

>&2 echo "-----"

sourc env.sh

echo
echo "Restoring dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

if [ "${RESTORE}" == "**None**" ]; then
  exit
elif [ "${RESTORE}" == "latest" ]; then
  SRC_FILE="$(aws $AWS_ARGS s3 ls s3://$S3_BUCKET/$S3_PREFIX/ | grep " PRE " -v | sort | head -1 | cut -d " " -f 4 | sed -e 's/\r//g'| sed -e 's/\n//g')"
else
  SRC_FILE=${RESTORE}
fi

SRC_FILE=$DEST_FILE
aws $AWS_ARGS s3 cp s3://$S3_BUCKET/$S3_PREFIX/$SRC_FILE $DEST_FILE  || exit 2

if [ "${ENCRYPTION_PASSWORD}" = "**None**" ]; then
  DEST_FILE=$SRC_FILE
else
  DEST_FILE="${$SRC_FILE%.*}"

  >&2 echo "Decrypting ${SRC_FILE}"
  openssl -aes-256-cbc -d -a -in $SRC_FILE -out $DEST_FILE -k $ENCRYPTION_PASSWORD
  if [ $? != 0 ]; then
    >&2 echo "Error Decrypting ${SRC_FILE}"
  fi
  rm $SRC_FILE
  SRC_FILE=$DEST_FILE
fi


SRC_FILE=dump.sql.gz
DEST_FILE=${POSTGRES_DATABASE}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz

if [ "${POSTGRES_DATABASE}" == "all" ]; then
  echo "Can't restore all"
  exit 2
else
  echo "Restoring with pg_restore"
  pg_restore $POSTGRES_HOST_OPTS -1 -f $SRC_FILE
fi



echo "SQL restore finished"

>&2 echo "-----"