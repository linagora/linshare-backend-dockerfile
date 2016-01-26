#! /bin/bash -x

# Check mandatory parameters
fail=0
[[ -z "$SMTP_HOST" && -z "$LS_SMTP_PORT_25_TCP_ADDR" ]] && fail=1
[[ -z "$POSTGRES_URL" && -z "$POSTGRES_HOST" && -z "$LS_POSTGRES_PORT_5432_TCP_ADDR" ]] && fail=1
[ $fail -eq 1 ] && echo "Missing mandatory paramater, SMPT_HOST and POSTGRES_HOST must be set." && exit 1

[ -z "$POSTGRES_URL" ] || echo "Warning : POSTGRES_URL parameter is deprecated. Please use POSTGRES_HOST instead."

# DEFAULT VALUES

smtp_port=25
clamd_port=3310
postgres_port=5432
smtp_auth_needed="false"

# OPENSMTPD SETTINGS

[ -z "$SMTP_HOST" ] || smtp_host="$SMTP_HOST"
[ -z "$SMTP_PORT" ] || smtp_port="$SMTP_PORT"
[ -z "$SMTP_USER" ] || smtp_user="$SMTP_USER"
[ -z "$SMTP_PASS" ] || smtp_password="$SMTP_PASS"
[ -z "$SMTP_USER" ] || smtp_auth_needed="true"
[ -z "$SMTP_PASS" ] || smtp_auth_needed="true"
[ -z "$LS_SMTP_PORT_25_TCP_ADDR" ] || smtp_host="$LS_SMTP_PORT_25_TCP_ADDR"
[ -z "$LS_SMTP_PORT_25_TCP_PORT" ] || smtp_port="$LS_SMTP_PORT_25_TCP_PORT"
echo "smtp host : $smtp_host"
echo "smtp port : $smtp_port"
echo "smtp auth needed : $smtp_auth_needed"

# POSTGRESQL SETTINGS

[ -z "$POSTGRES_USER" ] || postgres_username="$POSTGRES_USER"
[ -z "$POSTGRES_PASS" ] || postgres_password="$POSTGRES_PASS"
[ -z "$POSTGRES_HOST" ] || postgres_host="$POSTGRES_HOST"
[ -z "$POSTGRES_PORT" ] || postgres_port="$POSTGRES_PORT"
[ -z "$POSTGRES_URL" ]  || postgres_url="$POSTGRES_URL"
[ -z "$LS_POSTGRES_PORT_5432_TCP_ADDR" ] || postgres_host="$LS_POSTGRES_PORT_5432_TCP_ADDR"
[ -z "$LS_POSTGRES_PORT_5432_TCP_PORT" ] || postgres_port="$LS_POSTGRES_PORT_5432_TCP_PORT"
echo "postgres host : $LS_POSTGRES_PORT_5432_TCP_ADDR"
echo "postgres port : $LS_POSTGRES_PORT_5432_TCP_PORT"

# CLAMAV SETTINGS

[ -z "$CLAMAV_HOST" ] || clamav_host="$CLAMAV_HOST"
[ -z "$CLAMAV_PORT" ] || clamav_port="$CLAMAV_PORT"
[ -z "$LS_CLAMAV_PORT_3310_TCP_ADDR" ] || clamav_host="$LS_CLAMAV_PORT_3310_TCP_ADDR"
[ -z "$LS_CLAMAV_PORT_3310_TCP_PORT" ] || clamav_port="$LS_CLAMAV_PORT_3310_TCP_PORT"

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
unzip -qq webapps/linshare.war -d webapps/linshare

# Making /etc/linshare if doesn't exists
[ -d /etc/linshare ] || mkdir /etc/linshare

custom_linshare=0
custom_log4j=0

# Copying configuration files for later customization
[ -f "${conf_dir}/linshare.properties" ] && custom_linshare=1
[ -f "${conf_dir}/log4j.properties" ] && custom_log4j=1
[ $custom_linshare -eq 0 ] && cp ${src_dir}/linshare.properties.sample ${conf_dir}/linshare.properties
[ $custom_log4j -eq 0 ] && cp ${src_dir}/log4j.properties ${conf_dir}/log4j.properties
[ $custom_log4j -eq 0 ] && sed -i "s/log4j.category.org.linagora.linshare.*/log4j.category.org.linagora.linshare=info/" ${conf_dir}/log4j.properties

if [ $custom_linshare -eq 0 ]; then
    echo -e "Configuring Linshare settings"
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

    [ -z "$postgres_username" ] || sed -i "s@\(.*user.*value=\"\).*\(\".*\)@\1${postgres_username}\2@" $target2
    [ -z "$postgres_password" ] || sed -i "s@\(.*password.*value=\"\).*\(\".*\)@\1${postgres_password}\2@" $target2
    [ -z "$postgres_url" ]      || sed -i "s@\(.*url.*value=\"\).*\(\".*\)@\1${postgres_url}_data\2@" $target2
    [ -z "$postgres_host" ]     || sed -i "s@\(.*url.*value=\"\).*\(\".*\)@\1jdbc:postgresql://${postgres_host}:${postgres_port}/linshare_data\2@" $target2

fi

sed -i "s@#log4j.category.org.springframework.*@log4j.category.org.springframework=warn@" /etc/linshare/log4j.properties
sed -i "s@log4j.category.org.linagora.linkit.*@log4j.category.org.linagora.linkit=warn@" /etc/linshare/log4j.properties
sed -i "s@log4j.category.org.linagora.linshare.*@log4j.category.org.linagora.linshare=warn@" /etc/linshare/log4j.properties

/bin/bash /usr/local/tomcat/bin/catalina.sh run

