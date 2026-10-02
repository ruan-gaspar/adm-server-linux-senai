```bash
#!/bin/bash

# ============================================================
# 06 - NAT / IP FORWARD
# ============================================================
#
# Interface externa:
# enp0s3
#
# Rede interna:
# 172.20.0.0/16
# ============================================================


if [ "$EUID" -ne 0 ]; then

    echo "Execute com sudo:"
    echo "sudo ./06-nat.sh"

    exit 1

fi


# ============================================================
# CONFIGURAÇÃO
#
# Conforme solicitado, esta etapa entra em sudo su antes
# das alterações do iptables.
# ============================================================

sudo su <<'NAT_CONFIG'


# ------------------------------------------------------------
# Ativar encaminhamento IPv4
# ------------------------------------------------------------

echo 1 > /proc/sys/net/ipv4/ip_forward


# ------------------------------------------------------------
# NAT
# ------------------------------------------------------------

iptables -t nat -A POSTROUTING \
    -o enp0s3 \
    -s 172.20.0.0/16 \
    -j MASQUERADE


NAT_CONFIG


# ============================================================
# EVIDÊNCIAS
# ============================================================

echo
echo "============================================================"
echo " NAT / IP FORWARD"
echo "============================================================"


echo
echo "--- IP FORWARD ---"

cat /proc/sys/net/ipv4/ip_forward


echo
echo "--- INTERFACES ---"

ip -br addr


echo
echo "--- ROTAS ---"

ip route


echo
echo "--- IPTABLES INPUT ---"

sudo su <<'IPTABLES_INPUT'

iptables -L INPUT -n --line-numbers

IPTABLES_INPUT


echo
echo "--- IPTABLES NAT ---"

sudo su <<'IPTABLES_NAT'

iptables -t nat -L POSTROUTING -n --line-numbers

IPTABLES_NAT


echo
echo "============================================================"
echo " NAT CONFIGURADO"
echo "============================================================"
```
