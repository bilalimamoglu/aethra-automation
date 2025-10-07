FROM n8nio/n8n:1.113.3

USER root
# Minimal tools: psql (for DB waits/queries), curl (health check), mc (MinIO client), bash (entrypoint)
RUN apk add --no-cache ca-certificates curl bash minio-client postgresql16-client gettext && \
    update-ca-certificates && \
    # Alpine names the client 'mcli'; keep 'mc' for convenience
    if [ -x /usr/bin/mcli ] && [ ! -e /usr/bin/mc ]; then ln -s /usr/bin/mcli /usr/bin/mc; fi

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
