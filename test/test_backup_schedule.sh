#!/bin/bash
sleep 2
docker run -i --rm --network local  jbergknoff/postgresql-client \
   -vON_ERROR_STOP=ON postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE <<-EOSQL
    drop table mytable;
EOSQL
docker run -d --rm --network local --name postgresql-backup-s3 -p 18080:18080 \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e SCHEDULE  -e DELETE_OLDER_THAN \
  postgresql-backup-s3
sleep 7
docker run -i --rm --network local  jbergknoff/postgresql-client \
   -vON_ERROR_STOP=ON postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE <<-EOSQL
    create table mytable(myint integer);
EOSQL
sleep 7
docker exec postgresql-backup-s3 cat /var/log/backup.log
docker kill postgresql-backup-s3
docker rm postgresql-backup-s3
docker kill $POSTGRES_HOST
docker volume rm pgdata