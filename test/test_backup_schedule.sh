#!/bin/bash
docker run -d --rm --network local --name postgresql-backup-s3 -p 18080:18080 \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD \
  -e SCHEDULE  -e DELETE_OLDER_THAN \
  postgresql-backup-s3
sleep 30
docker exec postgresql-backup-s3 cat /var/log/backup.log
docker kill postgresql-backup-s3
docker rm postgresql-backup-s3
docker kill $POSTGRES_HOST
docker volume rm pgdata