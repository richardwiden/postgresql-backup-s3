#!/bin/bash
set -e

docker volume create ${POSTGRES_VOLUME};
docker run --rm --network ${TEST_NETWORK} --name ${POSTGRES_HOST} -d -p 5432 \
  -e POSTGRES_DB=$POSTGRES_DATABASE \
  -e POSTGRES_DATABASE \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_PORT \
  -v ${POSTGRES_VOLUME}:/var/lib/postgresql/data \
  "${POSTGRES_BASE_IMAGE}"

sleep 1

docker run --rm --network ${TEST_NETWORK}  --name ${POSTGRES_BACKUP_HOST}  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e RESTORE \
  ${POSTGRES_BACKUP_IMAGE}
