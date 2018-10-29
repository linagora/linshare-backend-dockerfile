#! /bin/bash -e

# if START_DEBUG=1, debug traces will be displayed.
export DEBUG=${DEBUG:-0}
if [ ${DEBUG} -eq 1 ] ; then
    set -x
fi
export START_DEBUG=${START_DEBUG:-0}

# if LS_DEBUG=1, log4 debug traces will be displayed.
export LS_DEBUG=${LS_DEBUG:-0}

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

if [ "${STORAGE_MODE}" != "filesystem" ] ; then
    echo "INFO: STORAGE_MODE is different than filesystem"
    echo "INFO: checking object storage configuration ..."

    if [ "${STORAGE_MODE}" == "s3" ] ; then
        # a whole refactoring is needed. #ugly
        export OS_AUTH_URL=${AWS_AUTH_URL}
        export OS_USERNAME=${AWS_ACCESS_KEY_ID}
        export STORAGE_SWIFT_IDENTITY=${AWS_ACCESS_KEY_ID}
        export OS_PASSWORD=${AWS_SECRET_ACCESS_KEY}
        export OS_REGION_NAME=${AWS_REGION}

        echo "INFO: checking AWS S3 configuration ..."
        if [ -z "${AWS_AUTH_URL}" ] ; then
            echo "ERROR : No AWS_AUTH_URL configured, interrupting startup"
            exit 1
        fi
        if [ -z "${AWS_ACCESS_KEY_ID}" ] ; then
            echo "ERROR : No AWS_ACCESS_KEY_ID configured, interrupting startup"
            exit 1
        fi
        if [ ${START_DEBUG} -eq 1 ] ; then
            echo "storage s3 access key : ${STORAGE_SWIFT_IDENTITY:0:4}..."
        fi

        if [ -z "${AWS_SECRET_ACCESS_KEY}" ] ; then
            echo "ERROR : No AWS_SECRET_ACCESS_KEY configured, interrupting startup"
            exit 1
        fi

        if [ -z "${AWS_REGION}" ] ; then
            echo "WARN : No AWS_REGION configured"
        fi
        echo "INFO: OpenStack configuration checked"
    else
        echo "INFO: checking OpenStack configuration ..."
        if [ -z "${OS_AUTH_URL}" ] ; then
            echo "ERROR : No OS_AUTH_URL configured, interrupting startup"
            exit 1
        fi

        if [ -z "${OS_TENANT_ID}" ] ; then
            echo "ERROR : No OS_TENANT_ID configured, interrupting startup"
            exit 1
        fi

        if [ -z "${OS_TENANT_NAME}" ] ; then
            echo "ERROR : No OS_TENANT_NAME configured, interrupting startup"
            exit 1
        fi
        if [ -z "${OS_USERNAME}" ] ; then
            echo "ERROR : No OS_USERNAME configured, interrupting startup"
            exit 1
        fi

        export STORAGE_SWIFT_IDENTITY="${OS_TENANT_NAME}:${OS_USERNAME}"
        if [ ${START_DEBUG} -eq 1 ] ; then
            echo "storage swift identity : ${STORAGE_SWIFT_IDENTITY:0:4}..."
        fi

        if [ -z "${OS_PASSWORD}" ] ; then
            echo "ERROR : No OS_PASSWORD configured, interrupting startup"
            exit 1
        fi

        if [ -z "${OS_REGION_NAME}" ] ; then
            echo "WARN : No OS_REGION_NAME configured"
        fi
        echo "INFO: OpenStack configuration checked"
    fi
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
echo "storage endpoint : ${OS_AUTH_URL}"
if [ ${START_DEBUG} -eq 1 ] ; then
    echo "storage tenant id : ${OS_TENANT_ID:0:4}..."
    echo "storage tenant name : ${OS_TENANT_NAME:0:4}..."
    echo "storage username : ${OS_USERNAME:0:4}..."
    echo "storage password : ${OS_PASSWORD:0:4}..."
else
    echo "storage tenant id : xxx"
    echo "storage tenant name : xxx"
    echo "storage username : xxx"
    echo "storage password : xxx"
fi
echo "storage region id (optional) : ${OS_REGION_NAME}"
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
    sed -i 's@linshare.documents.storage.swift.credential=.*@linshare.documents.storage.swift.credential=${OS_PASSWORD:-""}@' $target
    sed -i 's@linshare.documents.storage.swift.endpoint=.*@linshare.documents.storage.swift.endpoint=${OS_AUTH_URL:-""}@' $target
    sed -i 's@# linshare.documents.storage.swift.regionId=.*@linshare.documents.storage.swift.regionId=${OS_REGION_NAME:-""}@' $target

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

    if [ ${LS_DEBUG} -eq 1 ] ; then
        sed -i "s@log4j.category.org.linagora.linshare=.*@log4j.category.org.linagora.linshare=debug@" ${conf_dir}/log4j.properties
    fi
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

l_input_dir=/new-ca
if [ -d ${l_input_dir} ] ; then
    echo "INFO: Folder ${l_input_dir} exists, adding all files as new CA ..."
    l_output_dir=/usr/share/ca-certificates/linshare/
    mkdir -p ${l_output_dir}
    for l_file in $(ls ${l_input_dir}/)
    do
        cp -v ${l_input_dir}/${l_file} ${l_output_dir}
        echo "linshare/${l_file}" >> /etc/ca-certificates.conf
    done
else
    echo "INFO: no extra ca found in folder ${l_input_dir}."
fi
echo "linagora/GandiStandardSSLCA2.pem" >> /etc/ca-certificates.conf
update-ca-certificates

exec /usr/local/tomcat/bin/catalina.sh run
