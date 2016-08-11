#! /bin/bash -e

# Check for deprecated parameters
[ ! -z "$POSTGRES_URL" ] && {
    echo "POSTGRES_URL parameter is deprecated. Please use POSTGRES_HOST instead."
    echo "Startup interrupted"
    exit 1
}

# Check for unused parameters
[ -z "$SMTP_HOST" ] && {
    echo "ERROR : No SMTP host configured, interrupting startup"
    exit 1
}

[ -z "$SMTP_PORT" ] && {
    echo "ERROR : No SMTP port configured, interrupting startup"
    exit 1
}

[ -z "$POSTGRES_HOST" ] && {
    echo "ERROR : No POSTGRES host configured, interrupting startup"
    exit 1
}

[ -z "$POSTGRES_PORT" ] && {
    echo "ERROR : No POSTGRES port configured, interrupting startup"
    exit 1
}

[ -z "$MONGODB_HOST" ] && {
    echo "ERROR : No MONGODB host configured, interrupting startup"
    exit 1
}

[ -z "$MONGODB_PORT" ] && {
    echo "ERROR : No MONGODB port configured, interrupting startup"
    exit 1
}

[ -z "$POSTGRES_USER" ] && {
    echo "ERROR : no POSTGRES_USER configured, interrupting startup"
    exit 1
}

[ -z "$POSTGRES_PASS" ] && {
    echo "ERROR : no POSTGRES_PASS configured, interrupting startup"
    exit 1
}

[ -z "$CLAMAV_PORT" ] && {
    echo "ERROR : No CLAMAV_PORT configured, interrupting startup"
    exit 1
}

# OPENSMTPD SETTINGS
[ -z "$SMTP_HOST" ] || smtp_host="$SMTP_HOST"
[ -z "$SMTP_PORT" ] || smtp_port="$SMTP_PORT"
[ -z "$SMTP_USER" ] || smtp_user="$SMTP_USER"
[ -z "$SMTP_PASS" ] || smtp_password="$SMTP_PASS"
[ -z "$SMTP_USER" ] || smtp_auth_needed="true"
[ -z "$SMTP_PASS" ] || smtp_auth_needed="true"
echo "smtp host : $smtp_host"
echo "smtp port : $smtp_port"
echo "smtp auth needed : $smtp_auth_needed"

# POSTGRESQL SETTINGS
[ -z "$POSTGRES_HOST" ] || postgres_host="$POSTGRES_HOST"
[ -z "$POSTGRES_USER" ] || postgres_username="$POSTGRES_USER"
[ -z "$POSTGRES_PASS" ] || postgres_password="$POSTGRES_PASS"
[ -z "$POSTGRES_PORT" ] || postgres_port="$POSTGRES_PORT"
[ -z "$POSTGRES_URL" ]  || postgres_url="$POSTGRES_URL"


# CLAMAV SETTINGS
[ -z "$CLAMAV_HOST" ] || clamav_host="$CLAMAV_HOST"
[ -z "$CLAMAV_PORT" ] || clamav_port="$CLAMAV_PORT"

# LINSHARE OPTIONS (WARNING : modifying these settings is at your own risks)
src_dir=webapps/linshare/WEB-INF/classes
conf_dir=/etc/linshare
data_dir=/var/lib/linshare

# Allow to tweak JVM settings
[ -z "$JAVA_OPTS" ] || java_opts="$JAVA_OPTS"
export JAVA_OPTS="-Djava.awt.headless=true -Xms512m -Xmx1536m -XX:-UseSplitVerifier
                  -XX:+UseConcMarkSweepGC -XX:MaxPermSize=256m
                  -Dlinshare.config.path=file:${conf_dir}/
                  -Dlog4j.configuration=file:${conf_dir}/log4j.properties
                  ${java_opts}"

# Extracting .war's files
unzip -o -qq webapps/linshare.war -d webapps/linshare

# Making /etc/linshare if doesn't exists
[ -d /etc/linshare ] || mkdir /etc/linshare

custom_linshare=0
custom_log4j=0

# Copying configuration files for later customization
[ -f "${conf_dir}/linshare.properties" ] && custom_linshare=1
[ -f "${conf_dir}/log4j.properties" ] && custom_log4j=1

if [ $custom_linshare -eq 1 ]; then
    echo -e "Custom linshare.properties found at ${conf_dir}"
    echo -e "Skipping configuration"
else
    echo -e "Configuring Linshare settings"

    cp ${src_dir}/linshare.properties.sample ${conf_dir}/linshare.properties

    target="${conf_dir}/linshare.properties"
    target2="${data_dir}/repository/workspaces/default/workspace.xml"

    # Uncommenting clamav related configuration if needed
    [ -z "$smtp_host" ]         || sed -i "s@mail.smtp.host.*@mail.smtp.host=${smtp_host}@" $target
    [ -z "$smtp_port" ]         || sed -i "s@mail.smtp.port.*@mail.smtp.port=${smtp_port}@" $target
    [ -z "$smtp_user" ]         || sed -i "s@mail.smtp.user.*@mail.smtp.user=${smtp_user}@" $target
    [ -z "$smtp_password" ]     || sed -i "s@mail.smtp.password.*@mail.smtp.password=${smtp_password}@" $target
    [ -z "$smtp_auth_needed" ]  || sed -i "s@mail.smtp.auth.needed.*@mail.smtp.auth.needed=true@" $target
    [ -z "$postgres_username" ] || sed -i "s@linshare.db.username.*@linshare.db.username=${postgres_username}@" $target
    [ -z "$postgres_password" ] || sed -i "s@linshare.db.password.*@linshare.db.password=${postgres_password}@" $target
    [ -z "$postgres_url" ]      || sed -i "s@.*linshare.db.url=jdbc:postgresql.*@linshare.db.url=${postgres_url}@" $target
    [ -z "$postgres_host" ]     || sed -i "s@linshare.db.url=jdbc:postgresql.*@linshare.db.url=jdbc:postgresql://${postgres_host}:${postgres_port}/linshare@" $target
    [ -z "$clamav_host" ]        || sed -i "s@.*virusscanner.clamav.host.*@virusscanner.clamav.host=${clamav_host}@" $target
    [ -z "$clamav_port" ]        || sed -i "s@.*virusscanner.clamav.port.*@virusscanner.clamav.port=${clamav_port}@" $target
    sed -i "s@linshare.logo.webapp.visible.*@linshare.logo.webapp.visible=false@" $target
    echo -e "linshare.display.licenceTerm=false\n" >> $target

    if [ -f $target2 ]; then
        [ -z "$postgres_username" ] \
        || sed -i "s@\(.*user.*value=\"\).*\(\".*\)@\1${postgres_username}\2@" $target2
        [ -z "$postgres_password" ] \
        || sed -i "s@\(.*password.*value=\"\).*\(\".*\)@\1${postgres_password}\2@" $target2
        [ -z "$postgres_url" ] \
        || sed -i "s@\(.*url.*value=\"\).*\(\".*\)@\1${postgres_url}_data\2@" $target2
        [ -z "$postgres_host" ] \
        || sed -i "s@\(.*url.*value=\"\).*\(\".*\)@\1jdbc:postgresql://${postgres_host}:${postgres_port}/linshare_data\2@" $target2
    fi

    sed -i "s@linshare.mongo.host=.*@linshare.mongo.host=${MONGODB_HOST}@" $target
    sed -i "s@linshare.mongo.port=.*@linshare.mongo.port=${MONGODB_PORT}@" $target

fi

if [ $custom_log4j -eq 1 ]; then
    echo -e "Custom log4j.properties found at ${conf_dir}"
    echo -e "Skipping configuration"
else
    echo -e "Configuring Log4j settings"

    cp ${src_dir}/log4j.properties ${conf_dir}/log4j.properties

    sed -i "s/log4j.category.org.linagora.linshare.*/log4j.category.org.linagora.linshare=info/" ${conf_dir}/log4j.properties

    sed -i "s@#log4j.category.org.springframework.*@log4j.category.org.springframework=warn@" ${conf_dir}/log4j.properties
    sed -i "s@log4j.category.org.linagora.linkit.*@log4j.category.org.linagora.linkit=warn@" ${conf_dir}/log4j.properties
    sed -i "s@log4j.category.org.linagora.linshare.*@log4j.category.org.linagora.linshare=warn@" ${conf_dir}/log4j.properties
fi

/bin/bash /usr/local/tomcat/bin/catalina.sh run

