FROM tomcat:7

MAINTAINER MAINTAINER Thomas Sarboni <tsarboni@linagora.com>

EXPOSE 8080

ARG VERSION
ARG CHANNEL="releases"

RUN echo "$CHANNEL" | grep "releases" 2>&1 > /dev/null \
 && URL="https://nexus.linagora.com/service/local/artifact/maven/content?r=linshare-${CHANNEL}&g=org.linagora.linshare&a=linshare-core&v=${VERSION}&p=war" \
 || URL="https://nexus.linagora.com/service/local/artifact/maven/content?r=linshare-${CHANNEL}&g=org.linagora.linshare&a=linshare-core&v=${VERSION}-SNAPSHOT&p=war"; \
 wget --no-check-certificate --progress=bar:force:noscroll -O webapps/linshare.war "${URL}"

COPY start.sh /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]

