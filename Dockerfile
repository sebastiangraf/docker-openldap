FROM debian:10.0

MAINTAINER sebastian.graf@konschtanz.de

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ldap-utils \
        slapd \
        vim \
		ldapscripts && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mv /etc/ldap /etc/ldap.dist & mv /etc/ldapscripts /etc/ldapscripts.dist

EXPOSE 389

VOLUME ["/etc/ldap", "/var/lib/ldap", "/etc/ldapscripts"]

ADD resources /tmp

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["slapd", "-d", "32768"]
