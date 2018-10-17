FROM tomcat:8-jre8-slim

MAINTAINER LinShare <linshare@linagora.com>

EXPOSE 8080

ARG VERSION="2.2.0-1"
ARG CHANNEL="releases"
ARG EXT="com"

ENV LINSHARE_VERSION=$VERSION
ENV START_DEBUG=0

ENV POSTGRES_HOST="" POSTGRES_PORT=5432 POSTGRES_DATABASE=linshare POSTGRES_USER=linshare POSTGRES_PASSWORD=linshare
ENV MONGODB_HOST="" MONGODB_PORT=27017 MONGODB_USER=mongo MONGODB_PASSWORD=mongo
ENV REPLICA_SET="" REPLICA_SET_BIGFILES="" REPLICA_SET_SMALLFILES=""
ENV THUMBNAIL_ENABLE=false THUMBNAIL_HOST=undefined THUMBNAIL_PORT=8080 THUMBNAIL_ENABLE_PDF=true
ENV SMTP_HOST="" SMTP_PORT=25 SMTP_USER="" SMTP_PASSWORD="" SMTP_AUTH_ENABLE=false CLAMAV_HOST=undefined CLAMAV_PORT=3310
ENV STORAGE_MODE=filesystem STORAGE_BUCKET=linshare-data STORAGE_FILESYSTEM_DIR=/var/lib/linshare/filesystemstorage
ENV JWT_EXPIRATION=300 JWT_TOKEN_MAX_LIFETIME=300 SSO_IP_LIST="" SSO_IP_LIST_ENABLE=false

RUN apt-get update && apt-get install -y --no-install-recommends wget unzip && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN URL="https://nexus.linagora.${EXT}/service/local/artifact/maven/content?r=linshare-${CHANNEL}&g=org.linagora.linshare&a=linshare-core&v=${VERSION}"; \
 wget --no-check-certificate --progress=bar:force:noscroll \
 -O webapps/linshare.war "${URL}&p=war" \
 && wget --no-check-certificate --progress=bar:force:noscroll \
 -O linshare.war.sha1 "${URL}&p=war.sha1" \
 && sed -i 's#^\(.*\)#\1\twebapps/linshare.war#' linshare.war.sha1 \
 && sha1sum -c linshare.war.sha1 && rm -f linshare.war.sha1 \
 && sed -i "/xom/i\jclouds-bouncycastle-1.9.2.jar,bcprov-*.jar,\\\ " /usr/local/tomcat/conf/catalina.properties

COPY start.sh /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]

