#!/bin/bash
set -e
./test/setup_postgres.sh no_init

EXPECTED_ERROR_CODE=33

docker run --network "${TEST_NETWORK}" --name "${POSTGRES_BACKUP_HOST}"  -d \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  "${POSTGRES_BACKUP_IMAGE}"

postgres_backup_status=""
while [ "${postgres_backup_status}" == "" ] ;
do
  postgres_backup_status=$(docker ps|grep "${POSTGRES_BACKUP_HOST}")
  echo "Status: ${postgres_backup_status}"
  sleep 0.1s
done

set +e
docker exec -i "${POSTGRES_BACKUP_HOST}" sh -c "sh run.sh; exit \$?"
ERROR_CODE=$?
set -e

if [ "${ERROR_CODE}" != "${EXPECTED_ERROR_CODE}" ] ; then
  echo "Error code is: ${ERROR_CODE} but it should be: ${EXPECTED_ERROR_CODE}"
  echo "Message: -----"
  echo "${ERROR_MESSAGE}"
  exit 1
fi

