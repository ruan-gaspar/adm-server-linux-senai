```bash
#!/bin/bash

# ============================================================
# 05 - SAMBA
# ============================================================


if [ "$EUID" -ne 0 ]; then

    echo "Execute com sudo:"
    echo "sudo ./05-samba.sh"

    exit 1

fi


# ------------------------------------------------------------
# Variáveis
# ------------------------------------------------------------

USUARIO_ADM="admincrefisa"
USUARIO_COMPRAS="comprascrefisa"

SENHA_ADM="Admin@123"
SENHA_COMPRAS="Compras@123"

GRUPO_ADM="administrativo"
GRUPO_COMPRAS="compras"


# ------------------------------------------------------------
# Instalação
# ------------------------------------------------------------

apt update

apt install samba -y


# ------------------------------------------------------------
# Parar Samba
# ------------------------------------------------------------

systemctl stop smbd


# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------

cp /etc/samba/smb.conf \
   /etc/samba/smb.conf.bkp


# ------------------------------------------------------------
# Grupos
# ------------------------------------------------------------

if ! getent group "$GRUPO_ADM" > /dev/null; then

    groupadd "$GRUPO_ADM"

fi


if ! getent group "$GRUPO_COMPRAS" > /dev/null; then

    groupadd "$GRUPO_COMPRAS"

fi


# ------------------------------------------------------------
# Usuários
# ------------------------------------------------------------

if ! id "$USUARIO_ADM" > /dev/null 2>&1; then

    adduser \
        --disabled-password \
        --gecos "" \
        "$USUARIO_ADM"

fi


if ! id "$USUARIO_COMPRAS" > /dev/null 2>&1; then

    adduser \
        --disabled-password \
        --gecos "" \
        "$USUARIO_COMPRAS"

fi


# ------------------------------------------------------------
# Grupos
# ------------------------------------------------------------

usermod -aG \
    "$GRUPO_ADM" \
    "$USUARIO_ADM"


usermod -aG \
    "$GRUPO_COMPRAS" \
    "$USUARIO_COMPRAS"


# ------------------------------------------------------------
# Senhas Samba
# ------------------------------------------------------------

printf "%s\n%s\n" \
    "$SENHA_ADM" \
    "$SENHA_ADM" \
    | smbpasswd -a -s "$USUARIO_ADM"


printf "%s\n%s\n" \
    "$SENHA_COMPRAS" \
    "$SENHA_COMPRAS" \
    | smbpasswd -a -s "$USUARIO_COMPRAS"


# ------------------------------------------------------------
# Diretórios
# ------------------------------------------------------------

mkdir -p \
    /srv/samba/administrativo


mkdir -p \
    /srv/samba/compras


# ------------------------------------------------------------
# Permissões
# ------------------------------------------------------------

chown -R \
    root:"$GRUPO_ADM" \
    /srv/samba/administrativo


chmod -R \
    2775 \
    /srv/samba/administrativo


chown -R \
    root:"$GRUPO_COMPRAS" \
    /srv/samba/compras


chmod -R \
    2775 \
    /srv/samba/compras


# ------------------------------------------------------------
# Configuração
# ------------------------------------------------------------

cat >> /etc/samba/smb.conf <<EOF


[administrativo]

    path = /srv/samba/administrativo

    browseable = yes

    read only = no

    valid users = @$GRUPO_ADM

    force group = $GRUPO_ADM

    create mask = 0664

    directory mask = 2775


[compras]

    path = /srv/samba/compras

    browseable = yes

    read only = no

    valid users = @$GRUPO_COMPRAS

    force group = $GRUPO_COMPRAS

    create mask = 0664

    directory mask = 2775

EOF


# ------------------------------------------------------------
# Teste
# ------------------------------------------------------------

testparm -s


if [ $? -ne 0 ]; then

    echo "ERRO na configuração do Samba."

    exit 1

fi


# ------------------------------------------------------------
# Serviço
# ------------------------------------------------------------

systemctl start smbd

systemctl restart smbd

systemctl enable smbd


# ============================================================
# EVIDÊNCIAS
# ============================================================

echo
echo "============================================================"
echo " SAMBA - CONFIGURAÇÃO"
echo "============================================================"


echo
echo "--- smb.conf ---"

cat /etc/samba/smb.conf


echo
echo "--- DIRETÓRIOS ---"

ls -ld \
    /srv/samba/administrativo \
    /srv/samba/compras


echo
echo "--- GRUPOS ---"

getent group administrativo

getent group compras


echo
echo "--- USUÁRIOS ---"

id admincrefisa

id comprascrefisa


echo
echo "--- STATUS SAMBA ---"

systemctl status smbd --no-pager


echo
echo "============================================================"
echo " SAMBA CONFIGURADO E ATIVO"
echo "============================================================"


echo
echo "No Windows:"
echo
echo "\\\\172.20.0.1\\administrativo"
echo "\\\\172.20.0.1\\compras"

```
