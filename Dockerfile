FROM tomcat:8-jre8

MAINTAINER LinShare <linshare@linagora.com>

EXPOSE 8080

ARG VERSION="2.0.0-beta1"
ARG CHANNEL="releases"
ARG EXT="com"

RUN URL="https://nexus.linagora.${EXT}/service/local/artifact/maven/content?r=linshare-${CHANNEL}&g=org.linagora.linshare&a=linshare-core&v=${VERSION}"; \
 wget --no-check-certificate --progress=bar:force:noscroll \
 -O webapps/linshare.war "${URL}&p=war" \
 && wget --no-check-certificate --progress=bar:force:noscroll \
 -O linshare.war.sha1 "${URL}&p=war.sha1" \
 && sed -i 's#^\(.*\)#\1\twebapps/linshare.war#' linshare.war.sha1 \
 && sha1sum -c linshare.war.sha1 --quiet && rm -f linshare.war.sha1

COPY start.sh /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]

