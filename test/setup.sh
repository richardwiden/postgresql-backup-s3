#!/bin/bash
./test/tear_down.sh

docker network create local
docker run --rm --network local --name s3 -d -p 9000 \
  -e USER="$S3_ACCESS_KEY_ID" \
  -e PASSWORD="$S3_SECRET_ACCESS_KEY" \
  altmannmarcelo/minio:latest

sleep 1

docker run --rm --network local --name aws \
  -e AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY" \
  -e AWS_EC2_METADATA_DISABLED=true \
  amazon/aws-cli \
    --endpoint-url $S3_ENDPOINT \
    s3 mb s3://$S3_BUCKET
docker volume create pgdata
docker run --rm --network local --name $POSTGRES_HOST -d -p $POSTGRES_PORT \
  -e POSTGRES_DB=$POSTGRES_DATABASE \
  -e POSTGRES_DATABASE \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_PORT \
  -v pgdata:/var/lib/postgresql/data \
  postgres:14-alpine
docker cp ./test/test_db_setup.sh postgres:/docker-entrypoint-initdb.d/test_db_setup.sh

sleep 2

docker build docker -t postgresql-backup-s3


