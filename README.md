docker-openldap
===============

[![](https://badge.imagelayers.io/sebastiangraf/docker-openldap:latest.svg)](https://imagelayers.io/?images=sebastiangraf%2Fdocker-openldap:latest 'Get your own badge on imagelayers.io')

A Docker image running OpenLDAP on Debian stable ("jessie" at the moment). The
Dockerfile is inspired by
[dinkel/docker-openldap](https://github.com/dinkel/docker-openldap). Despite, it simplifies some password management and includes ldapscripts for easy generation of new users.

NOTE: On purpose, there is no secured channel (TLS/SSL), because I too believe that
this service should never be exposed to the internet, but only be used directly
by other Docker containers using the `--link` option.

Usage
-----

The most simple form would be to start the application like so (however this is
not the recommended way - see below):

    docker run -d -p 389:389 -e SLAPD_PASSWORD=mysecretpassword -e SLAPD_DOMAIN=ldap.example.org sebastiangraf/docker-openldap

An application talking to OpenLDAP should then `--link` the container:

    docker run -d --link openldap:openldap image-using-openldap

The name after the colon in the `--link` section is the hostname where the
OpenLDAP daemon is listening to (the port is the default port `389`).

Configuration (environment variables)
-------------------------------------

For the first run, one has to set exact two environment variables. The first

    SLAPD_PASSWORD

sets the password for the `admin` user. The password also allows password protected access to the `dn=config` branch. This helps to reconfigure the server without interruption (read the
[official documentation](http://www.openldap.org/doc/admin24/guide.html#Configuring%20slapd)).

The second

    SLAPD_DOMAIN

sets the DC (Domain component) parts. E.g. if one sets it to `ldap.example.org`,
the generated base DC parts would be `...,dc=ldap,dc=example,dc=org`.

After the first start of the image (and the initial configuration), these
envirnonment variables are not evaluated anymore.

Data persistence
----------------

The image exposes two directories (`VOLUME ["/etc/ldap", "/var/lib/ldap", "/etc/ldapscripts"]`).
The first holds the "static" configuration while the second holds the actual
database. The third includes the configs for ldapscripts.
Please make sure that these three directories are saved (in a data-only
container or alike) in order to make sure that everything is restored after a
restart of the container.
