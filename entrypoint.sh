#!/bin/bash

# When not limiting the open file descritors limit, the memory consumption of
# slapd is absurdly high. See https://github.com/docker/docker/issues/8231
ulimit -n 8192


set -e

chown -R openldap:openldap /var/lib/ldap/

if [[ ! -d /etc/ldap/slapd.d ]]; then

    if [[ -z "$SLAPD_PASSWORD" ]]; then
        echo -n >&2 "Error: Container not configured and SLAPD_PASSWORD not set. "
        echo >&2 "Did you forget to add -e SLAPD_PASSWORD=... ?"
        exit 1
    fi

    if [[ -z "$SLAPD_DOMAIN" ]]; then
        echo -n >&2 "Error: Container not configured and SLAPD_DOMAIN not set. "
        echo >&2 "Did you forget to add -e SLAPD_DOMAIN=... ?"
        exit 1
    fi

    dc_string=""
    IFS="."; declare -a dc_parts=($SLAPD_DOMAIN)
    for dc_part in "${dc_parts[@]}"; do
        dc_string="$dc_string,dc=$dc_part"
    done
    dc_string=${dc_string:1}

    cp -a /etc/ldap.dist/* /etc/ldap

    cat <<-EOF | debconf-set-selections
	    slapd slapd/no_configuration  boolean false
	    slapd slapd/internal/generated_adminpw password $SLAPD_PASSWORD
	    slapd slapd/internal/adminpw password $SLAPD_PASSWORD
	    slapd slapd/password1         password $SLAPD_PASSWORD
	    slapd slapd/password2         password $SLAPD_PASSWORD
	    slapd slapd/domain            string $SLAPD_DOMAIN
	    slapd shared/organization     string $SLAPD_DOMAIN
	    slapd slapd/allow_ldap_v2     boolean false
	    slapd slapd/purge_database    boolean false
	    slapd slapd/move_old_database boolean true
	    slapd slapd/purge_database    boolean false
	    slapd slapd/backend           string HDB
	    slapd slapd/dump_database     select when needed
EOF

    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive slapd
    
    base_string="BASE ${dc_string}"
    sed -i "s/^#BASE.*/${base_string}/g" /etc/ldap/ldap.conf

    cp -a /tmp/conf/* /etc/ldapscripts
    sed -i "s/{{ldap_dc}}/${dc_string}/g" /etc/ldapscripts/ldapscripts.conf
    sed -i "s/{{ldap_domain}}/${SLAPD_DOMAIN}/g" /etc/ldapscripts/ldapadduser.template
    sed -i "s/{{ldap_password}}/${SLAPD_PASSWORD}/g" /etc/ldapscripts/ldapscripts.passwd
	
    sed -i "s/{{ldap_dc}}/${dc_string}/g" /tmp/tmp/create_users_and_groups.ldif
    service slapd start
    ldapadd -w $SLAPD_PASSWORD -x -D cn=admin,$dc_string -f /tmp/tmp/create_users_and_groups.ldif
    kill -TERM `cat /var/run/slapd/slapd.pid`
    sleep 10
else
    slapd_configs_in_env=`env | grep 'SLAPD_'`

    if [ -n "${slapd_configs_in_env:+x}" ]; then
        echo "Info: Container already configured, therefore ignoring SLAPD_xxx environment variables"
    fi
fi

exec "$@"
