#!/bin/bash
docker pull -q amazon/aws-cli
docker pull -q ${POSTGRES_BASE_IMAGE}
docker pull -q ${POSTGRES_CLIENT_IMAGE}
docker pull -q bitnami/minio:latest
docker build docker -t ${POSTGRES_BACKUP_IMAGE} --build-arg POSTGRES_BASE_IMAGE
