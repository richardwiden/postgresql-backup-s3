docker kill s3 > /dev/null  2>&1 || true
docker rm s3 > /dev/null  2>&1 || true
docker kill $POSTGRES_HOST > /dev/null  2>&1 || true
docker rm $POSTGRES_HOST > /dev/null  2>&1 || true
docker kill postgresql-backup-s3 > /dev/null  2>&1 || true
docker rm postgresql-backup-s3 > /dev/null  2>&1 || true
docker network rm local > /dev/null  2>&1 || true
docker volume rm pgdata > /dev/null  2>&1 || true