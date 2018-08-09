Dockerfile link
===============

- [`linshare-backend-dockerfile`](https://github.com/linagora/linshare-backend-dockerfile/blob/master/Dockerfile)

What is Linshare?
=================

Open Source secure files sharing application, LinShare is an easy solution to make dematerialized exchanges. For businesses which want confidentiality, and traceability for their file exchanges. LinShare is a libre and free, ergonomic and intuitive software, for transferring large files.

Functionalities
---------------

</br>

* **File upload** into its own personal space,
* **File sharing** to internal, external, or guest persons,
* **Shares management** and collaborative exchange space,
* **Security** : authentication, time-stamping, signature, confidentiality, and anti-virus filter,


How to use this image
=====================

To be fully operational, Linshare requires several components :
* **SMTP** server
* **Database** server (Postgres drivers included)
* **ClamAV** service (optional)

Configuration
-------------

You can configure the above related settings through the following environment variables :

| Environment variable              | Description
|-----------------------------------|---------------------------------------------------------------------------------------------------
|CLAMAV_HOST                        | clamav host
|CLAMAV_PORT                        | clamav port
|JAVA_OPTS                          | java env variables
|SMTP_HOST                          | smtp host
|SMTP_PORT                          | smtp port
|SMTP_USER                          | smtp user
|SMTP_PASS                          | smtp password
|POSTGRES_HOST                      | postgres host
|POSTGRES_PORT                      | postgres port
|POSTGRES_USER                      | postgres user
|POSTGRES_PASS                      | postgres password
|POSTGRES_DATABASE                  | postgres database with default value "linshare"
|MONGODB_HOST                       | mongodb host
|MONGODB_PORT                       | mongodb port
|MONGODB_USER                       | mongodb user
|MONGODB_PASS                       | mongodb password
|REPLICA_SET (optional)             | replica-set for "linshare" database (if not set MONGODB_HOST and MONGODB_PORT will be used)
|REPLICA_SET_BIGFILES (optional)    | replica-set for "linshare-files" database (if not set MONGODB_HOST and MONGODB_PORT will be used)
|REPLICA_SET_SMALLFILES (optional)  | replica-set for "linshare-bigfiles" database (if not set MONGODB_HOST and MONGODB_PORT will be used)
|SPRING_PROFILES_ACTIVE (optional)  | default value is 'default,jcloud,mongo'. To enable sso, use 'sso,jcloud,mongo'
|SSO_IP_LIST_ENABLE                 | enable trusted list of sso server ip. (default=false)
|SSO_IP_LIST (optional)             | Trusted list of sso server ip.  (default="")
|STORAGE_MODE                       | Available storage mode: <ul><li>filesystem : storing documents on file system<br/>**dependent variables:**<ul><li>`STORAGE_BUCKET`</li><li>`STORAGE_FILESYSTEM_DIR`</li> </ul> <li>swift-keystone: storing documents into swift<br/>**dependent variables:** <ul> <li>`STORAGE_BUCKET`</li> <li>`OS_AUTH_URL`</li> <li>`OS_TENANT_ID`</li> <li>`OS_TENANT_NAME`</li> <li>`OS_USERNAME`</li> <li>`OS_PASSWORD`</li> </ul> </li> <li>openstack-swift: storing documents into swift with region support<br/>**dependent variables:** <ul> <li>`STORAGE_BUCKET`</li> <li>`OS_AUTH_URL`</li> <li>`OS_TENANT_ID`</li> <li>`OS_TENANT_NAME`</li> <li>`OS_USERNAME`</li> <li>`OS_PASSWORD`</li> <li>`OS_REGION_ID`</li> </ul> </li> <li>s3: storing documents into swift<br/>**dependent variables:** <ul> <li>`STORAGE_BUCKET`</li> <li>`AWS_AUTH_URL`</li> <li>`AWS_ACCESS_KEY_ID`</li> <li>`AWS_SECRET_ACCESS_KEY`</li> </ul> </li> </ul>
|STORAGE_BUCKET                     | storage bucket id; default: *linshare-data* (old value was *e0531829-8a75-49f8-bb30-4539574d66c7*)
|STORAGE_FILESYSTEM_DIR             | storage filesystem directory; default: */var/lib/linshare/filesystemstorage*
|OS_AUTH_URL                        | storage swift endpoint e.g.: *http://127.0.0.1:5000/v2.0*
|OS_TENANT_ID                       | storage swift tenant id
|OS_TENANT_NAME                     | storage swift tenant name
|OS_USERNAME                        | storage swift username
|OS_PASSWORD                        | storage swift password
|OS_REGION_ID (optional)            | Region ID is required only with openstack-swift.
|AWS_AUTH_URL                       | Endpoint of S3 server : ex: https://s3.amazonaws.com
|AWS_ACCESS_KEY_ID                  | S3 access key
|AWS_SECRET_ACCESS_KEY              | S3 secret access key
|THUMBNAIL_ENABLE (optional)        | By default it is disabled : false|true
|THUMBNAIL_HOST (optional)          | Thumbnail host : thumbnail-server
|THUMBNAIL_PORT (optional)          | Thumbnail port : 8080
|JWT_EXPIRATION (optional)          | Jwt expiration : 300
|JWT_TOKEN_MAX_LIFETIME (optional)  | Jwt token max lifetime : 300
|START_DEBUG                        | if equal to 1, additionnal debug traces will be displayed.
|LS_DEBUG                           | if equal to 1, it enables debug traces for LinShare (log4j configuration)
<br/>

We add three mongodb environment variables in orther to specify the mongodb replica-set for each database.

Each environment variable must be set like this: "ip-adress-of-first-mongodb:mongodb-port,ip-adress-of-second-mongodb:mongodb-port,...".

For exemple if we had a replica-set of three mongodb replication for the "linshare-bigfiles" database we can add: 

`REPLICA_SET=10.129.0.3:27017,10.129.0.4:27017,10.129.0.5:27017`

Run
---

To start using this image with the defaults settings, you can run the following commands :

```console
$ docker run -d -p 8080:8080 linagora/linshare-backend
```

And if any changes are necessary you can set the new values by passing them as follow :

```console
$ docker run -it --rm -p 8080:8080 \
-e SMTP_HOST=smtp.linshare.com \
-e SMTP_PORT=25 \
-e SMTP_USER=linshare \
-e SMTP_PASS=linshare \
-e POSTGRES_HOST=postgres.linshare.com \
-e POSTGRES_USER=linshare \
-e POSTGRES_PASS=linshare \
-e CLAMAV_HOST=clamav.linshare.com \
-e CLAMAV_PORT=4410 \
-e JAVA_OPTS="-Xms1024m" \
linagora/linshare-backend
```

Data persistency
----------------

Data persistency on Docker host is provided by the Docker volume runtime flag (-v).

To enable it, at any time, run this image like as in the following example :

```console
$ docker run -d -p 8080:8080 -v /var/lib/linshare:/var/lib/linshare linagora/linshare-backend:1.11.4
```

Build
-----

This repository is capable of building stable or snapshot release of Linshare.
You can set a custom version number on the command-line by using the --build-args switch.

CHANNEL argument can be set to `releases` or `snapshots`.
Stable `releases` channel is selected by default.

Version is for Linshare-core version. It's set to latest version by default.

```console
$ docker build --build-arg CHANNEL=snapshots -t linshare-backend --build-arg VERSION=2.2.0-SNAPSHOT .
```

License
=======

View [license information](http://www.linshare.org/licenses/LinShare-License_AfferoGPL-v3_en.pdf) for the software contained in this image.

Supported Docker versions
=========================

This image is officially supported on Docker version 1.9.0.

Support for older versions (down to 1.6) is provided on a best-effort basis.

Please see [the Docker installation documentation](https://docs.docker.com/installation/) for details on how to upgrade your Docker daemon.

User Feedback
=============

Documentation
-------------

Official Linshare documentation is available here : [Linshare Configuration Guide (pdf format)](http://download.linshare.org/documentation/admins/Linagora_DOC_LinShare-1.7.0_Guide-Config-Admin_fr_20150303.pdf).


Issues
------

If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/linagora/linshare-backend/issues).
