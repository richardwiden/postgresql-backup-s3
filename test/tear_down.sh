#!/bin/bash
set -e

docker kill $S3_HOST > /dev/null  2>&1 || true
docker rm $S3_HOST > /dev/null  2>&1 || true
docker kill $POSTGRES_HOST > /dev/null  2>&1 || true
docker rm $POSTGRES_HOST > /dev/null  2>&1 || true
docker kill $POSTGRES_BACKUP_HOST > /dev/null  2>&1 || true
docker rm $POSTGRES_BACKUP_HOST > /dev/null  2>&1 || true
docker network rm ${TEST_NETWORK} > /dev/null  2>&1 || true
docker volume rm ${POSTGRES_VOLUME} > /dev/null  2>&1 || true
