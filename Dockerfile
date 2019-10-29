FROM tomcat:8-jre8-slim

MAINTAINER LinShare <linshare@linagora.com>

EXPOSE 8080

ARG VERSION="2.3.2"
ARG CHANNEL="releases"

ENV LINSHARE_VERSION=$VERSION
ENV START_DEBUG=0

COPY GandiStandardSSLCA2.pem /usr/share/ca-certificates/linagora/GandiStandardSSLCA2.pem

ENV POSTGRES_HOST="" POSTGRES_PORT=5432 POSTGRES_DATABASE=linshare POSTGRES_USER=linshare POSTGRES_PASSWORD=linshare
ENV MONGODB_URI=mongodb://mongodb/linshare MONGODB_URI_SMALLFILES=mongodb://mongodb/linshare-files
ENV MONGODB_URI_BIGFILES=mongodb://mongodb/linshare-bigfiles
ENV MONGODB_WRITE_CONCERN=MAJORITY
ENV THUMBNAIL_ENABLE=false THUMBNAIL_HOST=undefined THUMBNAIL_PORT=8080 THUMBNAIL_ENABLE_PDF=true
ENV SMTP_HOST="" SMTP_PORT=25 SMTP_USER="" SMTP_PASSWORD="" SMTP_AUTH_ENABLE=false CLAMAV_HOST=undefined CLAMAV_PORT=3310
ENV SMTP_START_TLS_ENABLE=false SMTP_SSL_ENABLE=false
ENV STORAGE_MODE=filesystem STORAGE_BUCKET=linshare-data STORAGE_FILESYSTEM_DIR=/var/lib/linshare/filesystemstorage
ENV JWT_EXPIRATION=300 JWT_TOKEN_MAX_LIFETIME=300 SSO_IP_LIST="" SSO_IP_LIST_ENABLE=false

RUN apt-get update && apt-get install -y --no-install-recommends unzip curl && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV URL="https://nexus.linagora.com/service/local/artifact/maven/content?r=linshare-${CHANNEL}&g=org.linagora.linshare&a=linshare-core&v=${VERSION}"
RUN curl -s "${URL}&p=war" -o webapps/linshare.war && curl -s "${URL}&p=war.sha1" -o linshare.war.sha1 \
  && sed -i 's#^\(.*\)#\1\twebapps/linshare.war#' linshare.war.sha1 \
  && sha1sum -c linshare.war.sha1 && rm -f linshare.war.sha1 \
  && sed -i "/xom/i\jclouds-bouncycastle-1.9.2.jar,bcprov-*.jar,\\\ " /usr/local/tomcat/conf/catalina.properties

COPY start.sh /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]
