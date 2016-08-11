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
* **Database** server (Postgres & MySQL drivers included)
* **ClamAV** service (optional)

Configuration
-------------

You can configure the above related settings through the following environment variables :

| Environment variable      |
|---------------------------|
|SMTP_HOST                  |
|SMTP_PORT                  |
|SMTP_USER                  |
|SMTP_PASS                  |
|POSTGRES_HOST              |
|POSTGRES_PORT              |
|POSTGRES_USER              |
|POSTGRES_PASS              |
|MONGODB_HOST               |
|MONGODB_PORT               |
|CLAMAV_HOST                |
|CLAMAV_PORT                |
|JAVA_OPTS                  |

<br/>

Example value for *POSTGRES_URL* : jdbc:postgresql://localhost:5432/linshare

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
$ docker build --build-arg VERSION=1.11.5 CHANNEL=snapshots -t linshare-backend .
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
