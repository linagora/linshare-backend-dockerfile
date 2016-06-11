FROM tomcat:7

MAINTAINER MAINTAINER Thomas Sarboni <tsarboni@linagora.com>

EXPOSE 8080

ARG VERSION="1.12.1"
ARG CHANNEL="releases"
ARG EXT="com"

RUN echo "$CHANNEL" | grep "releases" 2>&1 > /dev/null \
 && URL="https://nexus.linagora.${EXT}/service/local/artifact/maven/content?r=linshare-${CHANNEL}&g=org.linagora.linshare&a=linshare-core&v=${VERSION}" \
 || URL="https://nexus.linagora.${EXT}/service/local/artifact/maven/content?r=linshare-${CHANNEL}&g=org.linagora.linshare&a=linshare-core&v=${VERSION}-SNAPSHOT"; \
 wget --no-check-certificate --progress=bar:force:noscroll \
 -O webapps/linshare.war "${URL}&p=war" \
 && wget --no-check-certificate --progress=bar:force:noscroll \
 -O linshare.war.sha1 "${URL}&p=war.sha1" \
 && sed -i 's#^\(.*\)#\1\twebapps/linshare.war#' linshare.war.sha1 \
 && sha1sum -c linshare.war.sha1 --quiet && rm -f linshare.war.sha1

COPY start.sh /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]

