#!/bin/bash
set -e
EXPECTED_REMOVED_BACKUPS_COUNT=1
sleep 2
docker run -i --rm --network "${TEST_NETWORK}" "${POSTGRES_CLIENT_IMAGE}" \
   -vON_ERROR_STOP=ON "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DATABASE}" <<-EOSQL
    drop table mytable;
EOSQL

docker run -d --rm --network ${TEST_NETWORK} --name ${POSTGRES_BACKUP_HOST} -p ${POSTGRES_PORT} \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e SCHEDULE  -e DELETE_OLDER_THAN \
  ${POSTGRES_BACKUP_IMAGE}
sleep 15

REMOVED_BACKUPS_COUNT=$(docker logs "${POSTGRES_BACKUP_HOST}" 2>&1 | grep -c "Deleting old backup")

docker run -i --rm --network ${TEST_NETWORK} ${POSTGRES_CLIENT_IMAGE} \
   -vON_ERROR_STOP=ON postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DATABASE} <<-EOSQL
    create table mytable(myint integer);
EOSQL
sleep 7

if [ ${REMOVED_BACKUPS_COUNT} -ne ${EXPECTED_REMOVED_BACKUPS_COUNT} ]; then
  echo "Expected ${EXPECTED_REMOVED_BACKUPS_COUNT} removed backups, but got ${REMOVED_BACKUPS_COUNT}"
  exit 1
fi

docker kill "${POSTGRES_BACKUP_HOST}"
docker kill "${POSTGRES_HOST}"
docker volume rm "${POSTGRES_VOLUME}"
