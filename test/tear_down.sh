docker kill s3 > /dev/null  2>&1 || true
docker kill $POSTGRES_HOST > /dev/null  2>&1 || true
docker kill postgresql-backup-s3 > /dev/null  2>&1 || true
docker network rm local > /dev/null  2>&1 || true