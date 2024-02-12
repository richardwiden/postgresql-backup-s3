#!/bin/bash
docker volume create "${POSTGRES_VOLUME}";
docker run --rm --network "${TEST_NETWORK}" --name "${POSTGRES_HOST}" -d -p "${POSTGRES_PORT}" \
  -e POSTGRES_DB=${POSTGRES_DATABASE} \
  -e POSTGRES_DATABASE \
  -e POSTGRES_USER \
  -e POSTGRES_PASSWORD \
  -e POSTGRES_PORT \
  -v "${POSTGRES_VOLUME}":/var/lib/postgresql/data \
  --health-cmd pg_isready --health-interval 1s --health-timeout 1s --health-retries 10 \
  "${POSTGRES_BASE_IMAGE}"

if [ "$1" != "no_init" ];
then
  docker cp ./test/test_db_setup.sh ${POSTGRES_HOST}:/docker-entrypoint-initdb.d/test_db_setup.sh
fi
while [ "$health_status" != "healthy" ]; do
    health_status=$(docker inspect --format='{{.State.Health.Status}}' "${POSTGRES_HOST}")
    sleep 0.01s
done
echo "${POSTGRES_HOST}: $health_status"
