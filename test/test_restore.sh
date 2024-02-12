#!/bin/bash
set -e
./test/setup_postgres.sh no_init

sleep 1

docker run --rm --network ${TEST_NETWORK}  --name ${POSTGRES_BACKUP_HOST}  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e RESTORE \
  ${POSTGRES_BACKUP_IMAGE}

docker run --network ${TEST_NETWORK} --rm \
  ${POSTGRES_CLIENT_IMAGE} \
  postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE -c "select * from mytable;"
