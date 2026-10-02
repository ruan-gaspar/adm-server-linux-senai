```bash
#!/bin/bash

# ============================================================
# 02 - SERVIDOR DHCP
# ============================================================
#
# Rede:
# 172.20.0.0/16
#
# Faixa DHCP:
# 172.20.0.100 - 172.20.0.200
#
# Gateway:
# 172.20.0.1
#
# DNS:
# 172.20.0.1
# ============================================================


if [ "$EUID" -ne 0 ]; then

    echo "Execute com sudo:"
    echo "sudo ./02-dhcp.sh"

    exit 1

fi


# ------------------------------------------------------------
# Instalação
# ------------------------------------------------------------

apt update

apt install isc-dhcp-server -y


# ------------------------------------------------------------
# Parar serviço
# ------------------------------------------------------------

systemctl stop isc-dhcp-server


# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------

cp /etc/dhcp/dhcpd.conf \
   /etc/dhcp/dhcpd.conf.bkp


cp /etc/default/isc-dhcp-server \
   /etc/default/isc-dhcp-server.bkp


# ------------------------------------------------------------
# Configuração DHCP
# ------------------------------------------------------------

cat > /etc/dhcp/dhcpd.conf <<EOF

default-lease-time 600;

max-lease-time 7200;

authoritative;


subnet 172.20.0.0 netmask 255.255.0.0 {

    range 172.20.0.100 172.20.0.200;

    option subnet-mask 255.255.0.0;

    option routers 172.20.0.1;

    option broadcast-address 172.20.255.255;

    option domain-name "crefisa.local";

    option domain-name-servers 172.20.0.1;

}

EOF


# ------------------------------------------------------------
# Interface DHCP
# ------------------------------------------------------------

cat > /etc/default/isc-dhcp-server <<EOF

INTERFACESv4="enp0s8"

#INTERFACESv6=""

EOF


# ------------------------------------------------------------
# Serviço
# ------------------------------------------------------------

systemctl start isc-dhcp-server

systemctl restart isc-dhcp-server

systemctl enable isc-dhcp-server


# ============================================================
# EVIDÊNCIAS
# ============================================================

echo
echo "============================================================"
echo " DHCP - CONFIGURAÇÃO"
echo "============================================================"

echo
echo "--- dhcpd.conf ---"

cat /etc/dhcp/dhcpd.conf


echo
echo "--- Interface DHCP ---"

cat /etc/default/isc-dhcp-server


echo
echo "--- STATUS DO DHCP ---"

systemctl status isc-dhcp-server --no-pager


echo
echo "--- LOG DO DHCP ---"

echo "Últimas mensagens relacionadas ao DHCP:"

grep dhcpd /var/log/syslog | tail -20


echo
echo "============================================================"
echo " DHCP CONFIGURADO E ATIVO"
echo "============================================================"
```
