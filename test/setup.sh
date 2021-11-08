#!/bin/bash
./test/tear_down.sh

docker network create local
docker run --rm --network local --name s3 -d -p 9000:9000 \
  -e USER="$S3_ACCESS_KEY_ID" \
  -e PASSWORD="$S3_SECRET_ACCESS_KEY" \
  altmannmarcelo/minio:latest
docker run --rm --network local --name aws \
  -e AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY" \
  -e AWS_EC2_METADATA_DISABLED=true \
  amazon/aws-cli \
    --endpoint-url $S3_ENDPOINT \
    s3 mb s3://$S3_BUCKET
docker run --rm --network local --name $POSTGRES_HOST -d -p "5432:5432" \
  -e POSTGRES_DB=$POSTGRES_DATABASE \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_PORT \
  -v /tests/test_db_setup.sh/init-user-db.sh \
  postgres:14

sleep 5
echo "Server should be up and running now"
