ARG POSTGRES_BASE_IMAGE=postgres:14-alpine
FROM $POSTGRES_BASE_IMAGE
LABEL maintainer="richardwiden@gmail.com"
ENV VIRTUAL_ENV=/opt/venv
RUN apk update && \
    apk add coreutils && \
    apk add tzdata && \
    apk add python3 py3-pip && \
       python3 -m venv $VIRTUAL_ENV && . /opt/venv/bin/activate && \
       pip3 install --upgrade awscli && \
    apk add openssl && \
    apk add curl && \
    curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron && chmod u+x /usr/local/bin/go-cron  && \
    apk del curl && \
    rm -rf /var/cache/apk/*
 
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

ENV POSTGRES_DATABASE=**None** \
    POSTGRES_HOST=**None** \
    POSTGRES_PORT='5432' \
    POSTGRES_USER=**None** \
    POSTGRES_PASSWORD=**None** \
    POSTGRES_EXTRA_OPTS='' \
    S3_ACCESS_KEY_ID=**None** \
    S3_SECRET_ACCESS_KEY=**None** \
    S3_BUCKET=**None** \
    S3_REGION=us-west-1 \
    S3_PREFIX='backup' \
    S3_ENDPOINT=**None** \
    S3_S3V4=no \
    SCHEDULE=**None** \
    ENCRYPTION_PASSWORD=**None** \
    DELETE_OLDER_THAN=**None**  \
    RESTORE=**None**

COPY backup.sh  restore.sh env.sh run.sh ./
RUN chmod 555 backup.sh  restore.sh env.sh run.sh
CMD ["sh", "run.sh"]
