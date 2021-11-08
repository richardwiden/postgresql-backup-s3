#!/bin/bash

docker build . -t postgresql-backup-s3
docker run --rm --network local --name postgresql-backup-s3  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET \
  postgresql-backup-s3
docker kill $POSTGRES_HOST