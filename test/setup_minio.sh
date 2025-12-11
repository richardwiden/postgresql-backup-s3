#!/bin/bash
set -e

docker run --rm --network "${TEST_NETWORK}" --name "${S3_HOST}" -d -p 9000 \
  -e MINIO_ROOT_USER="$S3_ACCESS_KEY_ID" \
  -e MINIO_ROOT_PASSWORD="$S3_SECRET_ACCESS_KEY" \
  -e MINIO_REGION="us-east-1" \
  --health-cmd "curl -I http://localhost:9000/minio/health/live" --health-start-period 5s --health-interval 1s --health-timeout 1s --health-retries 10 \
  firstfinger/minio:latest-amd64
sleep 1
while [ "$health_status" != "healthy" ]; do
    health_status=$(docker inspect --format='{{.State.Health.Status}}' "${S3_HOST}")
    sleep 0.01s
done
echo "${S3_HOST}: $health_status"

docker run --rm -i --network "${TEST_NETWORK}" --name "${AWS_CLI_HOST}" \
  -e AWS_ACCESS_KEY_ID="${S3_ACCESS_KEY_ID}" \
  -e AWS_SECRET_ACCESS_KEY="${S3_SECRET_ACCESS_KEY}" \
  -e AWS_EC2_METADATA_DISABLED=true \
  -e AWS_REGION="us-east-1" \
  amazon/aws-cli --endpoint-url "${S3_ENDPOINT}" s3 mb "s3://${S3_BUCKET}"
