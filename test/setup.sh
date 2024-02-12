#!/bin/bash
set -e

./test/tear_down.sh
docker network create ${TEST_NETWORK}
./test/setup_minio.sh
./test/setup_postgres.sh






