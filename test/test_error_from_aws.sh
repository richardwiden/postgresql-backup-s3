#!/bin/bash
docker volume create pgdata;
docker run --rm --network local --name "$POSTGRES_HOST" -d -p "5432:5432" \
  -e POSTGRES_DB=$POSTGRES_DATABASE \
  -e POSTGRES_DATABASE \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_PORT \
  -v pgdata:/var/lib/postgresql/data \
  "${POSTGRES_BASE_IMAGE}"

sleep 1

docker run --rm --network local --name postgresql-backup-s3  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e RESTORE \
  postgresql-backup-s3

docker run --network local --rm richardwiden/postgresql-client:edge-12 postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE -c "select * from mytable;"
