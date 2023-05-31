FROM ubuntu:18.04 as builder
ARG VERSION="2.2.0-SNAPSHOT"
ARG CHANNEL="snapshots"
ARG EXT="com"

RUN apt-get update && apt-get install -y --no-install-recommends wget unzip

RUN URL="https://nexus.linagora.${EXT}/service/local/artifact/maven/content?r=linshare-${CHANNEL}&g=org.linagora.linshare&a=linshare-core&v=${VERSION}"; \
 wget --no-check-certificate --progress=bar:force:noscroll \
 -O /tmp/linshare.war "${URL}&p=war"

FROM jetty:9-jre8

ENV LINSHARE_VERSION=$VERSION

MAINTAINER LinShare <linshare@linagora.com>

EXPOSE 8080

ENV START_DEBUG=0

ENV POSTGRES_HOST="" POSTGRES_PORT=5432 POSTGRES_DATABASE=linshare POSTGRES_USER=linshare POSTGRES_PASSWORD=linshare
ENV MONGODB_HOST=""  MONGODB_USER=mongo MONGODB_PASSWORD=mongo
ENV MONGODB_URI=mongodb://mongodb/linshare MONGODB_URI_SMALLFILES=mongodb://mongodb/linshare-files
ENV MONGODB_URI_BIGFILES=mongodb://mongodb/linshare-bigfiles
ENV MONGODB_WRITE_CONCERN=MAJORITY
ENV REPLICA_SET="" REPLICA_SET_BIGFILES="" REPLICA_SET_SMALLFILES=""
ENV THUMBNAIL_ENABLE=false THUMBNAIL_HOST=undefined THUMBNAIL_PORT=8080 THUMBNAIL_ENABLE_PDF=true
ENV SMTP_HOST="" SMTP_PORT=25 SMTP_USER="" SMTP_PASSWORD="" SMTP_AUTH_ENABLE=false CLAMAV_HOST=undefined CLAMAV_PORT=3310
ENV STORAGE_MODE=filesystem STORAGE_BUCKET=linshare-data STORAGE_FILESYSTEM_DIR=/var/lib/linshare/filesystemstorage
ENV JWT_EXPIRATION=300 JWT_TOKEN_MAX_LIFETIME=300 SSO_IP_LIST="" SSO_IP_LIST_ENABLE=false

COPY --from=builder /tmp/linshare.war webapps/linshare.war
COPY start.sh /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]
