#!/bin/bash
./test/tear_down.sh
docker pull -q amazon/aws-cli
docker pull -q ${POSTGRES_BASE_IMAGE}
docker pull -q ${POSTGRES_CLIENT_IMAGE}


docker network create ${TEST_NETWORK}
docker run --rm --network ${TEST_NETWORK} --name ${S3_HOST} -d -p 9000 \
  -e USER="$S3_ACCESS_KEY_ID" \
  -e PASSWORD="$S3_SECRET_ACCESS_KEY" \
  altmannmarcelo/minio:latest

sleep 1

docker run --rm --network ${TEST_NETWORK} --name ${AWS_CLI_HOST} \
  -e AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY" \
  -e AWS_EC2_METADATA_DISABLED=true \
  amazon/aws-cli \
    --endpoint-url $S3_ENDPOINT \
    s3 mb s3://$S3_BUCKET
docker volume create ${POSTGRES_VOLUME};
docker run --rm --network ${TEST_NETWORK} --name $POSTGRES_HOST -d -p $POSTGRES_PORT \
  -e POSTGRES_DB=$POSTGRES_DATABASE \
  -e POSTGRES_DATABASE \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_PORT \
  -v ${POSTGRES_VOLUME}:/var/lib/postgresql/data \
  "${POSTGRES_BASE_IMAGE}"
docker cp ./test/test_db_setup.sh ${POSTGRES_HOST}:/docker-entrypoint-initdb.d/test_db_setup.sh

sleep 2

docker build docker -t ${POSTGRES_BACKUP_IMAGE} --build-arg POSTGRES_BASE_IMAGE


