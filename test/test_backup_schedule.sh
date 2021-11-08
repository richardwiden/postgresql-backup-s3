#!/bin/bash
docker run -d --rm --network local --name postgresql-backup-s3  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e SCHEDULE \
  postgresql-backup-s3
for i in {10..60..10}
do
  sleep 10
  echo "Slept: $i seconds"
done
docker kill postgresql-backup-s3
docker kill $POSTGRES_HOST
docker volume rm pgdata