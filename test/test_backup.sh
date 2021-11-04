#!/bin/bash

POSTGRES_PORT=5432
docker build . -t postgresql-backup-s3
docker run --rm --network local --name postgresql-backup-s3  \
  -e POSTGRES_DATABASE \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_PORT \
  postgresql-backup-s3