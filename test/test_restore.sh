#!/bin/bash
docker run --rm --network local --name $POSTGRES_HOST -d -p "5432:5432" \
  -e POSTGRES_DATABASE \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_PORT \
  postgres:14-alpine

sleep 1

docker run --rm --network local --name postgresql-backup-s3  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET \
  -e RESTORE="latest" \
  postgresql-backup-s3

  docker run -it --network local --rm jbergknoff/postgresql-client postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE -c "select * from mytable;"