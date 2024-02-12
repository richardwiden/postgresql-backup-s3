#!/bin/bash
set -e
./test/setup_postgres.sh no_init

docker run -i --network "${TEST_NETWORK}" --name "${POSTGRES_BACKUP_HOST}"  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e RESTORE \
  "${POSTGRES_BACKUP_IMAGE}"

