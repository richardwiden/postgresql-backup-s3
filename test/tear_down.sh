docker kill s3 > /dev/null  2>&1 || true
docker kill postgres > /dev/null  2>&1 || true
docker network rm local > /dev/null  2>&1 || true