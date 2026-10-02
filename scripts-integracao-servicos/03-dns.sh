```bash
#!/bin/bash

# ============================================================
# 03 - SERVIDOR DNS / BIND9
# ============================================================
#
# Domínio:
# crefisa.local
#
# Registro:
# www.crefisa.local -> 172.20.0.1
# ============================================================


if [ "$EUID" -ne 0 ]; then

    echo "Execute com sudo:"
    echo "sudo ./03-dns.sh"

    exit 1

fi


# ------------------------------------------------------------
# Instalação
# ------------------------------------------------------------

apt update

apt install bind9 bind9utils bind9-doc dnsutils -y


# ------------------------------------------------------------
# Parar BIND
# ------------------------------------------------------------

systemctl stop bind9


# ------------------------------------------------------------
# Backups
# ------------------------------------------------------------

cp /etc/bind/named.conf.options \
   /etc/bind/named.conf.options.bkp


cp /etc/bind/named.conf.local \
   /etc/bind/named.conf.local.bkp


if [ -f /etc/default/named ]; then

    cp /etc/default/named \
       /etc/default/named.bkp

fi


# ------------------------------------------------------------
# named.conf.options
# ------------------------------------------------------------

cat > /etc/bind/named.conf.options <<EOF

acl internal-network {

    172.20.0.0/16;

};


options {

    directory "/var/cache/bind";

    allow-query {

        localhost;

        internal-network;

    };


    allow-transfer {

        localhost;

    };


    forwarders {

        10.107.132.4;

    };


    recursion yes;


    dnssec-validation no;

};

EOF


# ------------------------------------------------------------
# named.conf.local
# ------------------------------------------------------------

cat > /etc/bind/named.conf.local <<EOF

zone "crefisa.local" IN {

    type master;

    file "/etc/bind/forward.crefisa.local";

    allow-update { none; };

};


zone "20.172.in-addr.arpa" IN {

    type master;

    file "/etc/bind/reverse.crefisa.local";

    allow-update { none; };

};

EOF


# ------------------------------------------------------------
# Backup das zonas caso já existam
# ------------------------------------------------------------

if [ -f /etc/bind/forward.crefisa.local ]; then

    cp /etc/bind/forward.crefisa.local \
       /etc/bind/forward.crefisa.local.bkp

fi


if [ -f /etc/bind/reverse.crefisa.local ]; then

    cp /etc/bind/reverse.crefisa.local \
       /etc/bind/reverse.crefisa.local.bkp

fi


# ------------------------------------------------------------
# Zona direta
# ------------------------------------------------------------

cat > /etc/bind/forward.crefisa.local <<EOF

\$TTL 604800

@ IN SOA primary.crefisa.local. root.crefisa.local. (

    2026100201
    3600
    1800
    604800
    86400

)


@       IN NS primary.crefisa.local.

primary IN A 172.20.0.1

www     IN A 172.20.0.1

server  IN A 172.20.0.1

EOF


# ------------------------------------------------------------
# Zona reversa
# ------------------------------------------------------------

cat > /etc/bind/reverse.crefisa.local <<EOF

\$TTL 86400

@ IN SOA primary.crefisa.local. root.crefisa.local. (

    2026100201
    3600
    1800
    604800
    86400

)


@ IN NS primary.crefisa.local.

primary IN A 172.20.0.1

1.0 IN PTR primary.crefisa.local.

1.0 IN PTR www.crefisa.local.

1.0 IN PTR server.crefisa.local.

EOF


# ------------------------------------------------------------
# IPv4
# ------------------------------------------------------------

sed -i '/^OPTIONS=/d' /etc/default/named

echo 'OPTIONS="-u bind -4"' >> /etc/default/named


# ============================================================
# TESTES
# ============================================================

echo
echo "============================================================"
echo " TESTANDO CONFIGURAÇÃO DNS"
echo "============================================================"


named-checkconf

named-checkzone \
    crefisa.local \
    /etc/bind/forward.crefisa.local

named-checkzone \
    20.172.in-addr.arpa \
    /etc/bind/reverse.crefisa.local


# ------------------------------------------------------------
# Serviço
# ------------------------------------------------------------

systemctl start bind9

systemctl restart bind9

systemctl enable bind9


# ============================================================
# EVIDÊNCIAS
# ============================================================

echo
echo "============================================================"
echo " DNS - CONFIGURAÇÃO"
echo "============================================================"


echo
echo "--- named.conf.options ---"

cat /etc/bind/named.conf.options


echo
echo "--- named.conf.local ---"

cat /etc/bind/named.conf.local


echo
echo "--- Zona direta ---"

cat /etc/bind/forward.crefisa.local


echo
echo "--- Zona reversa ---"

cat /etc/bind/reverse.crefisa.local


echo
echo "--- STATUS DO BIND9 ---"

systemctl status bind9 --no-pager


echo
echo "--- TESTE www.crefisa.local ---"

dig @172.20.0.1 www.crefisa.local


echo
echo "============================================================"
echo " DNS CONFIGURADO E ATIVO"
echo "============================================================"
```
