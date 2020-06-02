#!/bin/bash
set -e
g_prog_name=$(basename $0)

# if START_DEBUG=1, debug traces will be displayed.
export DEBUG=${DEBUG:-0}
if [ ${DEBUG} -eq 1 ] ; then
    set -x
fi
export START_DEBUG=${START_DEBUG:-0}

# if LS_DEBUG=1, log4 debug traces will be displayed.
export LS_DEBUG=${LS_DEBUG:-0}


# Description: This method will check and display a list of env variables.
#              The value of every env variables with names containing SECRET or
#              PASSWORD will be troncated (only the first 4 characters).
# First parameter is `mode`:
# * mode=0 : just display env vars
# * mode=1 : the script will abort if some env var is missing.
# Second parameter is `legend`:
# * legend=0 : do not display the legend
# * legend=1 : display the legend
# Next parameters : ENV variables to test
# ex: check_env_variables 1 1 VAR1 VAR2 VAR4
function check_env_variables ()
{
    local l_mode=${1}
    local l_legend=${2}
    shift
    shift
    local l_error=0
    local l_key=
    local l_vars_list=$@

    if [ ${l_legend} -eq 1 ] ; then
        if [ ${l_mode} -eq 1 ] ; then
            echo "INFO:${g_prog_name}: Checking all required env variables..."
        else
            echo "INFO:${g_prog_name}: Checking all optional env variables..."
        fi
    fi
    for l_key in ${l_vars_list}
    do
        if [[ ${l_key} =~ PASSWORD || ${l_key} =~ SECRET ]] ; then
            if [ ${START_DEBUG} -eq 1 ] ; then
                echo "${l_key} : ${!l_key}"
            else
                echo "${l_key} : ${!l_key:0:4}..."
            fi
        else
            echo "${l_key} : ${!l_key}"
        fi
        if [ ${l_mode} -eq 1 ] ; then
            if [ -z ${!l_key} ] ; then
                l_error=1
            fi
        fi
    done
    if [ ${l_error} -eq 1 ] ; then
        echo "ERROR: Missing some input variables"
        echo
        exit 1
    fi
    [ ${l_legend} -eq 1 ] && echo -e "INFO:${g_prog_name}: All env variables checked\n"
    return ${l_error}
}

function check_deprecated_env_variables ()
{
    local l_key=$1
    local l_new_key=$2
    if [ ! -z ${!l_key} ] ; then
        echo "ERROR: ${l_key} is not supported anymore. See ${l_new_key}"
        echo
        exit 1
    fi
}

g_vars_list="
POSTGRES_HOST
SMTP_HOST
MONGODB_DATA_REPLICA_SET
MONGODB_SMALLFILES_REPLICA_SET
"
g_vars_list_opts="
POSTGRES_PORT
POSTGRES_DATABASE
POSTGRES_USER
POSTGRES_PASSWORD
SMTP_PORT
CLAMAV_HOST
CLAMAV_PORT
SMTP_AUTH_ENABLE
SMTP_USER
SMTP_PASSWORD
STORAGE_MODE
STORAGE_BUCKET
STORAGE_FILESYSTEM_DIR
JWT_EXPIRATION
JWT_TOKEN_MAX_LIFETIME
SSO_IP_LIST_ENABLE
SSO_IP_LIST
MONGODB_BIGFILES_REPLICA_SET
MONGODB_USER
MONGODB_PASSWORD
MONGODB_AUTH_DATABASE
OS_TENANT_NAME
"

# MAIN
[ -z "$SMTP_USER" ] || SMTP_AUTH_ENABLE="true"
[ -z "$SMTP_PASSWORD" ] || SMTP_AUTH_ENABLE="true"

check_env_variables 1 1 ${g_vars_list}
check_env_variables 0 1 ${g_vars_list_opts}

check_deprecated_env_variables MONGODB_URI MONGODB_DATA_REPLICA_SET
check_deprecated_env_variables MONGODB_URI_SMALLFILES MONGODB_SMALLFILES_REPLICA_SET
check_deprecated_env_variables MONGODB_URI_BIGFILES MONGODB_BIGFILES_REPLICA_SET
check_deprecated_env_variables MONGODB_HOST MONGODB_DATA_REPLICA_SET
check_deprecated_env_variables MONGODB_PORT MONGODB_DATA_REPLICA_SET

if [ "${STORAGE_MODE}" != "filesystem" ] ; then
    echo
    echo "INFO: STORAGE_MODE is different than filesystem: ${STORAGE_MODE}"
    echo "INFO: Checking object storage configuration ..."
    if [ "${STORAGE_MODE}" == "s3" ] ; then
        check_env_variables 1 0 AWS_AUTH_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
    else
        check_env_variables 1 0 OS_AUTH_URL OS_USERNAME OS_PASSWORD OS_REGION_NAME
        if [ "${OS_IDENTITY_API_VERSION}" == "3" ] ; then
            check_env_variables 1 0 OS_USER_DOMAIN_NAME OS_PROJECT_NAME
        fi
    fi
        echo "INFO: Object storage configuration checked"
    echo
fi

# LINSHARE OPTIONS (WARNING : modifying these settings is at your own risks)
src_dir=webapps/linshare/WEB-INF/classes
conf_dir=/etc/linshare
data_dir=/var/lib/linshare


# Allow to tweak JVM settings
[ -z "$JAVA_OPTS" ] || java_opts="$JAVA_OPTS"
export JAVA_OPTS="-Djava.awt.headless=true -Xms${JAVA_XMS} -Xmx${JAVA_XMX}
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
    echo -e "Configuring LinShare settings"

    cp ${src_dir}/linshare.properties.sample ${conf_dir}/linshare.properties

    target="${conf_dir}/linshare.properties"

    sed -i 's@mail.smtp.host.*@mail.smtp.host=${SMTP_HOST}@' $target
    sed -i 's@mail.smtp.port.*@mail.smtp.port=${SMTP_PORT}@' $target
    sed -i 's@mail.smtp.auth.needed.*@mail.smtp.auth.needed=${SMTP_AUTH_ENABLE}@' $target
    sed -i 's@mail.smtp.user.*@mail.smtp.user=${SMTP_USER}@' $target
    sed -i 's@mail.smtp.password.*@mail.smtp.password=${SMTP_PASSWORD}@' $target
    sed -i 's@mail.smtp.starttls.enable.*@mail.smtp.starttls.enable=${SMTP_START_TLS_ENABLE}@' $target
    sed -i 's@mail.smtp.ssl.enable.*@mail.smtp.ssl.enable=${SMTP_SSL_ENABLE}@' $target

    sed -i 's@linshare.db.url=jdbc:postgresql.*@linshare.db.url=jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DATABASE}@' $target
    sed -i 's@linshare.db.username.*@linshare.db.username=${POSTGRES_USER}@' $target
    sed -i 's@linshare.db.password.*@linshare.db.password=${POSTGRES_PASSWORD}@' $target

    sed -i 's@.*virusscanner.clamav.host.*@virusscanner.clamav.host=${CLAMAV_HOST}@' $target
    sed -i 's@.*virusscanner.clamav.port.*@virusscanner.clamav.port=${CLAMAV_PORT}@' $target

    sed -i -r 's/(linshare.mongo.data.replicaset=).*/\1${MONGODB_DATA_REPLICA_SET}/g' $target
    sed -i -r 's/(linshare.mongo.data.database=).*/\1${MONGODB_DATA_DATABASE}/g' $target

    sed -i -r 's/(linshare.mongo.smallfiles.replicaset=).*/\1${MONGODB_SMALLFILES_REPLICA_SET}/g' $target
    sed -i -r 's/(linshare.mongo.smallfiles.database=).*/\1${MONGODB_SMALLFILES_DATABASE}/g' $target

    sed -i -r 's/(linshare.mongo.bigfiles.replicaset=).*/\1${MONGODB_BIGFILES_REPLICA_SET}/g' $target
    sed -i -r 's/(linshare.mongo.bigfiles.database=).*/\1${MONGODB_BIGFILES_DATABASE}/g' $target

    if [ ! -z "${MONGODB_PASSWORD}" ] ; then
        sed -i -r 's/(linshare.mongo.data.credentials=).*/\1${MONGODB_USER}:${MONGODB_PASSWORD}@${MONGODB_AUTH_DATABASE}/g' $target
        sed -i -r 's/(linshare.mongo.smallfiles.credentials=).*/\1${MONGODB_USER}:${MONGODB_PASSWORD}@${MONGODB_AUTH_DATABASE}/g' $target
        sed -i -r 's/(linshare.mongo.bigfiles.credentials=).*/\1${MONGODB_USER}:${MONGODB_PASSWORD}@${MONGODB_AUTH_DATABASE}/g' $target
    fi

    sed -i 's@linshare.mongo.write.concern=.*@linshare.mongo.write.concern=${MONGODB_WRITE_CONCERN}@' $target

    sed -i 's@sso.header.allowfrom=.*@sso.header.allowfrom=${SSO_IP_LIST}@' $target
    sed -i 's@sso.header.allowfrom.enable=.*@sso.header.allowfrom.enable=${SSO_IP_LIST_ENABLE}@' $target

    sed -i 's@linshare.documents.storage.mode=.*@linshare.documents.storage.mode=${STORAGE_MODE}@' $target
    sed -i 's@linshare.documents.storage.bucket=.*@linshare.documents.storage.bucket=${STORAGE_BUCKET}@' $target
    sed -i 's@linshare.documents.storage.multipartupload=.*@linshare.documents.storage.multipartupload=${STORAGE_MULTIPART_UPLOAD}@' $target
    sed -i 's@linshare.documents.storage.filesystem.directory=.*@linshare.documents.storage.filesystem.directory=${STORAGE_FILESYSTEM_DIR}@' $target

    if [ "${STORAGE_MODE}" != "filesystem" ] ; then
        if [ "${STORAGE_MODE}" == "s3" ] ; then
            sed -i 's@linshare.documents.storage.identity=.*@linshare.documents.storage.identity=${AWS_ACCESS_KEY_ID}@' $target
            sed -i 's@linshare.documents.storage.credential=.*@linshare.documents.storage.credential=${AWS_SECRET_ACCESS_KEY}@' $target
            sed -i 's@linshare.documents.storage.endpoint=.*@linshare.documents.storage.endpoint=${AWS_AUTH_URL}@' $target
        else
            sed -i 's@linshare.documents.storage.keystone.version=.*@linshare.documents.storage.keystone.version=${OS_IDENTITY_API_VERSION}@' $target
            if [ ! -z ${OS_TENANT_NAME} ] ; then
                sed -i 's@linshare.documents.storage.identity=.*@linshare.documents.storage.identity=${OS_TENANT_NAME}:${OS_USERNAME}@' $target
            fi
            sed -i 's@linshare.documents.storage.project.name=.*@linshare.documents.storage.project.name=${OS_PROJECT_NAME}@' $target
            sed -i 's@linshare.documents.storage.user.domain=.*@linshare.documents.storage.user.domain=${OS_USER_DOMAIN_NAME}@' $target
            sed -i 's@linshare.documents.storage.user.name=.*@linshare.documents.storage.user.name=${OS_USERNAME}@' $target
            sed -i 's@linshare.documents.storage.credential=.*@linshare.documents.storage.credential=${OS_PASSWORD}@' $target
            sed -i 's@linshare.documents.storage.endpoint=.*@linshare.documents.storage.endpoint=${OS_AUTH_URL}@' $target
            sed -i 's@linshare.documents.storage.regionId=.*@linshare.documents.storage.regionId=${OS_REGION_NAME}@' $target
        fi
    fi

    sed -i 's@linshare.documents.thumbnail.enable=.*@linshare.documents.thumbnail.enable=${THUMBNAIL_ENABLE}@' $target
    sed -i 's@linshare.documents.thumbnail.pdf.enable=.*@linshare.documents.thumbnail.pdf.enable=${THUMBNAIL_ENABLE_PDF}@' $target
    sed -i 's@linshare.linthumbnail.remote.mode=.*@linshare.linthumbnail.remote.mode=true@' $target
    sed -i 's@linshare.linthumbnail.dropwizard.server=.*@linshare.linthumbnail.dropwizard.server=http://${THUMBNAIL_HOST}:${THUMBNAIL_PORT}/linthumbnail?mimeType=%1$s@' $target

    sed -i 's@# jwt.expiration=.*@jwt.expiration=${JWT_EXPIRATION}@' $target
    sed -i 's@# jwt.token.max.lifetime=.*@jwt.expiration=${JWT_TOKEN_MAX_LIFETIME}@' $target

    echo -e "\n" >> $target
    echo -e "linshare.display.licenceTerm=${LICENSE:-true}\n" >> $target

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

if [ "${LINSHARE_PRODUCTION_MODE}" == "TRUE" ] ; then
    sed -i -e '/<session-config>/ a\        <tracking-mode>COOKIE</tracking-mode>' /usr/local/tomcat/conf/web.xml
    sed -i -e '/<\/Host>/ i\        <Valve className="org.apache.catalina.valves.ErrorReportValve" showServerInfo="false" showReport="false" />' /usr/local/tomcat/conf/server.xml
fi

exec /usr/local/tomcat/bin/catalina.sh run
