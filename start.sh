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

[ -z "${STORAGE_MODE}" ] && {
    export STORAGE_MODE=${STORAGE_MODE:-"filesystem"}
    echo "Warning : No STORAGE_MODE configured, default value will be \"${STORAGE_MODE}\""
}

[ -z "${STORAGE_BUCKET}" ] && {
    export STORAGE_BUCKET=${STORAGE_BUCKET:-"e0531829-8a75-49f8-bb30-4539574d66c7"}
    echo "Warning : No STORAGE_BUCKET configured, default value will be \"${STORAGE_BUCKET}\""
}

if [ -z "${STORAGE_FILESYSTEM_DIR}" ] ; then
  export STORAGE_FILESYSTEM_DIR=${STORAGE_FILESYSTEM_DIR:-"/var/lib/linshare/filesystemstorage"}
  echo "Warning : No STORAGE_FILESYSTEM_DIR configured, default value will be \"${STORAGE_FILESYSTEM_DIR}\""
fi

if [ "${STORAGE_MODE}" != "filesystem" -a -z "${STORAGE_SWIFT_IDENTITY}" ] ; then
    echo "ERROR : No STORAGE_SWIFT_IDENTITY configured, interrupting startup"
    exit 1
fi

if [ ${STORAGE_MODE} != "filesystem" -a -z "${STORAGE_SWIFT_CREDENTIAL}" ] ; then
    echo "ERROR : No STORAGE_SWIFT_CREDENTIAL configured, interrupting startup"
    exit 1
fi

if [ ${STORAGE_MODE} != "filesystem" -a -z "${STORAGE_SWIFT_ENDPOINT}" ] ; then
    echo "ERROR : No STORAGE_SWIFT_ENDPOINT configured, interrupting startup"
    exit 1
fi


# OPENSMTPD SETTINGS

[ -z "$SMTP_USER" ] || smtp_auth_needed="true"
[ -z "$SMTP_PASS" ] || smtp_auth_needed="true"

echo "smtp host : $SMTP_HOST"
echo "smtp port : $SMTP_PORT"
echo "smtp auth needed : $smtp_auth_needed"
echo "postgres host : $POSTGRES_HOST"
echo "postgres port : $POSTGRES_PORT"
echo "postgres user : $POSTGRES_USER"
echo "postgres database : $POSTGRES_DATABASE"
echo "mongodb host : $MONGODB_HOST"
echo "mongodb port : $MONGODB_PORT"
echo "mongodb user : $MONGODB_USER"
echo "clamav host : $CLAMAV_HOST"
echo "clamav port : $CLAMAV_PORT"
echo "storage mode : ${STORAGE_MODE}"
echo "storage bucket : ${STORAGE_BUCKET}"
echo "storage filesystem directory : ${STORAGE_FILESYSTEM_DIR}"
if [ -z ${STORAGE_SWIFT_IDENTITY} ] ; then
    echo "storage swift identity : ${STORAGE_SWIFT_IDENTITY}"
else
    echo "storage swift identity : xxxxxxxxx"
fi
if [ -z ${STORAGE_SWIFT_CREDENTIAL} ] ; then
    echo "storage swift credential : ${STORAGE_SWIFT_CREDENTIAL}"
else
    echo "storage swift credential : xxxxxxxxx"
fi
echo "storage swift endpoint : ${STORAGE_SWIFT_ENDPOINT}"
echo "storage swift region id (optional) : ${STORAGE_SWIFT_REGION_ID}"
echo "jwt secret (optional) : ${JWT_SECRET}"
echo "jwt expiration (optional) : ${JWT_EXPIRATION}"
echo "jwt token max lifetime (optional) : ${JWT_TOKEN_MAX_LIFETIME}"

 
# LINSHARE OPTIONS (WARNING : modifying these settings is at your own risks)
src_dir=webapps/linshare/WEB-INF/classes
conf_dir=/etc/linshare
data_dir=/var/lib/linshare


# Allow to tweak JVM settings
[ -z "$JAVA_OPTS" ] || java_opts="$JAVA_OPTS"
export JAVA_OPTS="-Djava.awt.headless=true -Xms512m -Xmx1536m
                  -XX:+UseConcMarkSweepGC
                  -Dlinshare.config.path=file:${conf_dir}/
                  -Dlog4j.configuration=file:${conf_dir}/log4j.properties
                  ${java_opts}"

# Extracting .war's files
unzip -o -qq webapps/linshare.war -d webapps/linshare

echo ">-------- Content of version.properties -----------"
cat ${src_dir}/version.properties
echo "--------- Content of version.properties ----------<"

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

    # Uncommenting clamav related configuration if needed

    [ -z "$SMTP_USER" ]         || sed -i 's@mail.smtp.user.*@mail.smtp.user=${SMTP_USER}@' $target
    [ -z "$SMTP_PASS" ]     || sed -i 's@mail.smtp.password.*@mail.smtp.password=${SMTP_PASS}@' $target
    [ -z "$smtp_auth_needed" ]  || sed -i 's@mail.smtp.auth.needed.*@mail.smtp.auth.needed=true@' $target
    sed -i 's@.*virusscanner.clamav.host.*@virusscanner.clamav.host=${CLAMAV_HOST:127.0.0.1}@' $target

    sed -i 's@mail.smtp.host.*@mail.smtp.host=${SMTP_HOST}@' $target
    sed -i 's@mail.smtp.port.*@mail.smtp.port=${SMTP_PORT}@' $target
    sed -i 's@linshare.db.username.*@linshare.db.username=${POSTGRES_USER}@' $target
    sed -i 's@linshare.db.password.*@linshare.db.password=${POSTGRES_PASS}@' $target
    sed -i 's@linshare.db.url=jdbc:postgresql.*@linshare.db.url=jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DATABASE:linshare}@' $target
    sed -i 's@.*virusscanner.clamav.port.*@virusscanner.clamav.port=${CLAMAV_PORT}@' $target

    sed -i 's@linshare.mongo.host=.*@linshare.mongo.host=${MONGODB_HOST}@' $target
    sed -i 's@linshare.mongo.gridfs.smallfiles.host=.*@linshare.mongo.gridfs.smallfiles.host=${MONGODB_HOST}@' $target
    sed -i 's@linshare.mongo.gridfs.bigfiles.host=.*@linshare.mongo.gridfs.bigfiles.host=${MONGODB_HOST}@' $target
    sed -i 's@linshare.mongo.port=.*@linshare.mongo.port=${MONGODB_PORT}@' $target
    sed -i 's@linshare.mongo.gridfs.smallfiles.port=.*@linshare.mongo.gridfs.smallfiles.port=${MONGODB_PORT}@' $target
    sed -i 's@linshare.mongo.gridfs.bigfiles.port=.*@linshare.mongo.gridfs.bigfiles.port=${MONGODB_PORT}@' $target
    sed -i 's@linshare.mongo.user=.*@linshare.mongo.user=${MONGODB_USER}@' $target
    sed -i 's@linshare.mongo.gridfs.smallfiles.user=.*@linshare.mongo.gridfs.smallfiles.user=${MONGODB_USER}@' $target
    sed -i 's@linshare.mongo.gridfs.bigfiles.user=.*@linshare.mongo.gridfs.bigfiles.user=${MONGODB_USER}@' $target
    sed -i 's@linshare.mongo.password=.*@linshare.mongo.password=${MONGODB_PASS}@' $target
    sed -i 's@linshare.mongo.gridfs.smallfiles.password=.*@linshare.mongo.gridfs.smallfiles.password=${MONGODB_PASS}@' $target
    sed -i 's@linshare.mongo.gridfs.bigfiles.password=.*@linshare.mongo.gridfs.bigfiles.password=${MONGODB_PASS}@' $target
    sed -i 's@sso.header.allowfrom=.*@sso.header.allowfrom=${SSO_IP_LIST:-""}@' $target
    sed -i 's@sso.header.allowfrom.enable=.*@sso.header.allowfrom.enable=${SSO_IP_LIST_ENABLE:-"false"}@' $target
    sed -i 's@linshare.documents.storage.mode=.*@linshare.documents.storage.mode=${STORAGE_MODE}@' $target
    sed -i 's@linshare.documents.storage.bucket=.*@linshare.documents.storage.bucket=${STORAGE_BUCKET}@' $target
    sed -i 's@linshare.documents.storage.filesystem.directory=.*@linshare.documents.storage.filesystem.directory=${STORAGE_FILESYSTEM_DIR}@' $target
    sed -i 's@linshare.documents.storage.swift.identity=.*@linshare.documents.storage.swift.identity=${STORAGE_SWIFT_IDENTITY:-""}@' $target
    sed -i 's@linshare.documents.storage.swift.credential=.*@linshare.documents.storage.swift.credential=${STORAGE_SWIFT_CREDENTIAL:-""}@' $target
    sed -i 's@linshare.documents.storage.swift.endpoint=.*@linshare.documents.storage.swift.endpoint=${STORAGE_SWIFT_ENDPOINT:-""}@' $target
    sed -i 's@# linshare.documents.storage.swift.regionId=.*@linshare.documents.storage.swift.regionId=${STORAGE_SWIFT_REGION_ID:-""}@' $target

    sed -i 's@linshare.documents.thumbnail.enable=.*@linshare.documents.thumbnail.enable=${THUMBNAIL_ENABLE}@' $target
    sed -i 's@linshare.documents.thumbnail.pdf.enable=.*@linshare.documents.thumbnail.pdf.enable=true@' $target
    sed -i 's@linshare.linthumbnail.remote.mode=.*@linshare.linthumbnail.remote.mode=true@' $target
    sed -i 's@linshare.linthumbnail.dropwizard.server=.*@linshare.linthumbnail.dropwizard.server=http://${THUMBNAIL_HOST}:${THUMBNAIL_PORT}/linthumbnail?mimeType=%1$s@' $target

    sed -i 's@# jwt.secret=.*@jwt.secret=${JWT_SECRET:-"mySecret"}@' $target
    sed -i 's@# jwt.expiration=.*@jwt.expiration=${JWT_EXPIRATION:-"300"}@' $target
    sed -i 's@# jwt.token.max.lifetime=.*@jwt.expiration=${JWT_TOKEN_MAX_LIFETIME:-"300"}@' $target

    echo -e "\n" >> $target
    echo -e "linshare.display.licenceTerm=false\n" >> $target
    echo -e 'linshare.mongo.replicatset=${REPLICA_SET:-""}\n' >> $target
    echo -e 'linshare.mongo.gridfs.bigfiles.replicatset=${REPLICA_SET_BIGFILES:-""}\n' >> $target
    echo -e 'linshare.mongo.gridfs.smallfiles.replicatset=${REPLICA_SET_SMALLFILES:-""}\n' >> $target


fi

if [ $custom_log4j -eq 1 ]; then
    echo -e "Custom log4j.properties found at ${conf_dir}"
    echo -e "Skipping configuration"
else
    echo -e "Configuring Log4j settings"

    cp ${src_dir}/log4j.properties ${conf_dir}/log4j.properties

fi


if [ -f "${conf_dir}/linshare.extra.properties" ] ; then
    if [ ! -f "${conf_dir}/linshare.extra.properties.added" ] ; then
        echo "Adding extra properties ..."
        cat ${conf_dir}/linshare.extra.properties
        echo ...
        cat ${conf_dir}/linshare.extra.properties  >> ${target}
        touch ${conf_dir}/linshare.extra.properties.added
    fi
else
    echo "There is no extra properties to set. Skipping."
fi


/bin/bash /usr/local/tomcat/bin/catalina.sh run

