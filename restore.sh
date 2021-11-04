#! /bin/sh

set -e
set -o pipefail

>&2 echo "-----"

if [ "${S3_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "You need to set the S3_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "${S3_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "${S3_BUCKET}" = "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${POSTGRES_DATABASE}" = "**None**" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

if [ "${S3_ENDPOINT}" == "**None**" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

# env vars needed for aws tools
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

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