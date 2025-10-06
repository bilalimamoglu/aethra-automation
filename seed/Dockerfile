FROM n8nio/n8n:1.113.3

USER root
# Need: psql (wait & check), curl (wait), mc (minio client), bash (for scripting)
RUN apk add --no-cache ca-certificates curl bash minio-client postgresql16-client && \
    update-ca-certificates && \
    # Alpine minio-client binary name is mcli; create mc symlink for convenience
    if [ -x /usr/bin/mcli ] && [ ! -e /usr/bin/mc ]; then ln -s /usr/bin/mcli /usr/bin/mc; fi

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
