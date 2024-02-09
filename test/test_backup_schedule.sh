#!/bin/bash
set -e

sleep 2
docker run -i --rm --network ${TEST_NETWORK} ${POSTGRES_CLIENT_IMAGE} \
   -vON_ERROR_STOP=ON postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE <<-EOSQL
    drop table mytable;
EOSQL

docker run -d --rm --network ${TEST_NETWORK} --name ${POSTGRES_BACKUP_HOST} -p ${POSTGRES_PORT} \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e SCHEDULE  -e DELETE_OLDER_THAN \
  ${POSTGRES_BACKUP_IMAGE}
sleep 7

docker run -i --rm --network ${TEST_NETWORK} ${POSTGRES_CLIENT_IMAGE} \
   -vON_ERROR_STOP=ON postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE <<-EOSQL
    create table mytable(myint integer);
EOSQL
sleep 7

docker exec ${POSTGRES_BACKUP_HOST}  cat /var/log/backup.log
docker kill ${POSTGRES_BACKUP_HOST}
docker kill ${POSTGRES_HOST}
docker volume rm ${POSTGRES_VOLUME}
