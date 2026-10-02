```bash
#!/bin/bash

# ============================================================
# 01 - CONFIGURAÇÃO DA REDE
# ============================================================
#
# enp0s3 = interface externa / Internet
# enp0s8 = interface interna / clientes
#
# Rede interna:
# 172.20.0.0/16
#
# IP do servidor:
# 172.20.0.1
# ============================================================


# Verifica se o script está sendo executado como root

if [ "$EUID" -ne 0 ]; then
    echo "Execute com sudo:"
    echo "sudo ./01-rede.sh"
    exit 1
fi


# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

INTERFACE_EXTERNA="enp0s3"
INTERFACE_INTERNA="enp0s8"

IP_SERVIDOR="172.20.0.1"


# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------

cp /etc/netplan/50-cloud-init.yaml \
   /etc/netplan/50-cloud-init.yaml.bkp


cp /etc/hosts \
   /etc/hosts.bkp


cp /etc/hostname \
   /etc/hostname.bkp


# ------------------------------------------------------------
# Hostname
# ------------------------------------------------------------

hostnamectl set-hostname crefisa-server


# ------------------------------------------------------------
# /etc/hosts
# ------------------------------------------------------------

if ! grep -q "crefisa-server" /etc/hosts; then

    echo "172.20.0.1    crefisa-server.crefisa.local crefisa-server" \
        >> /etc/hosts

fi


# ------------------------------------------------------------
# Netplan
# ------------------------------------------------------------

cat > /etc/netplan/50-cloud-init.yaml <<EOF

network:

  version: 2

  ethernets:

    enp0s3:
      dhcp4: true

    enp0s8:
      dhcp4: false

      addresses:
        - 172.20.0.1/16

      nameservers:
        addresses:
          - 172.20.0.1

EOF


chmod 600 /etc/netplan/50-cloud-init.yaml


# ------------------------------------------------------------
# Aplicar configuração
# ------------------------------------------------------------

netplan apply


# ============================================================
# EVIDÊNCIAS
# ============================================================

echo
echo "============================================================"
echo " CONFIGURAÇÃO DE REDE"
echo "============================================================"

echo
echo "--- IPs das interfaces ---"

ip -br addr


echo
echo "--- Rotas ---"

ip route


echo
echo "--- Netplan configurado ---"

cat /etc/netplan/50-cloud-init.yaml


echo
echo "--- Hosts ---"

cat /etc/hosts


echo
echo "============================================================"
echo " REDE CONFIGURADA"
echo "============================================================"
```
