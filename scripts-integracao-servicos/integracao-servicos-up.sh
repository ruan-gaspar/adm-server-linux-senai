```bash
#!/bin/bash

# ============================================================
# SCRIPT DE INSTALAÇÃO E CONFIGURAÇÃO - LABORATÓRIO CREFISA
#
# Curso:
# Administrador de Servidores Linux
#
# Instituição:
# SENAI Professor Vicente Amato - Jandira/SP
#
# Serviços:
#   - Rede
#   - DHCP
#   - DNS / BIND9
#   - Apache
#   - Samba
#   - NAT / IP forwarding
#
# Rede:
#   172.20.0.0/16
#
# IP do servidor:
#   172.20.0.1
#
# Interface externa:
#   enp0s3
#
# Interface interna:
#   enp0s8
#
# IMPORTANTE:
# O script deve ser executado com sudo:
#
#   chmod +x instalar_crefisa.sh
#   sudo ./instalar_crefisa.sh
# ============================================================


# ============================================================
# 1. VERIFICAÇÃO DE PRIVILÉGIOS
# ============================================================

if [ "$EUID" -ne 0 ]; then

    echo "ERRO: este script precisa ser executado com sudo."
    echo
    echo "Execute:"
    echo "sudo ./instalar_crefisa.sh"

    exit 1

fi


# ============================================================
# 2. VARIÁVEIS
# ============================================================

INTERFACE_EXTERNA="enp0s3"
INTERFACE_INTERNA="enp0s8"

IP_SERVIDOR="172.20.0.1"

DOMINIO="crefisa.local"
HOSTNAME_SERVIDOR="crefisa-server"

DHCP_INICIO="172.20.0.100"
DHCP_FIM="172.20.0.200"


# ------------------------------------------------------------
# Usuários do Samba
#
# ALTERE AS SENHAS SE NECESSÁRIO.
# ------------------------------------------------------------

USUARIO_ADM="admincrefisa"
SENHA_ADM="Admin@123"

USUARIO_COMPRAS="comprascrefisa"
SENHA_COMPRAS="Compras@123"

GRUPO_ADM="administrativo"
GRUPO_COMPRAS="compras"


# ============================================================
# 3. FUNÇÃO PARA MOSTRAR ETAPAS
# ============================================================

etapa() {

    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
    echo

}


# ============================================================
# 4. FUNÇÃO PARA CRIAR BACKUP
#
# Recebe o caminho de um arquivo existente.
#
# Exemplo:
#
# backup_arquivo /etc/samba/smb.conf
#
# Resultado:
#
# /etc/samba/smb.conf.bkp
# ============================================================

backup_arquivo() {

    ARQUIVO="$1"

    if [ -f "$ARQUIVO" ]; then

        cp "$ARQUIVO" "$ARQUIVO.bkp"

        echo "Backup criado:"
        echo "$ARQUIVO.bkp"

    else

        echo "Arquivo original não encontrado:"
        echo "$ARQUIVO"

        echo "Nenhum backup necessário."

    fi

}


# ============================================================
# 5. ATUALIZAÇÃO DOS PACOTES
# ============================================================

etapa "ATUALIZANDO PACOTES"

apt update


# ============================================================
# 6. CONFIGURAÇÃO DO HOSTNAME
# ============================================================

etapa "CONFIGURANDO HOSTNAME"

# /etc/hostname será alterado pelo hostnamectl.
# Portanto, fazemos o backup antes da alteração.

backup_arquivo /etc/hostname

hostnamectl set-hostname "$HOSTNAME_SERVIDOR"


# ------------------------------------------------------------
# Backup e alteração do /etc/hosts
# ------------------------------------------------------------

backup_arquivo /etc/hosts

if ! grep -q "$HOSTNAME_SERVIDOR" /etc/hosts; then

    echo "$IP_SERVIDOR    $HOSTNAME_SERVIDOR.$DOMINIO $HOSTNAME_SERVIDOR" >> /etc/hosts

fi


# ============================================================
# 7. CONFIGURAÇÃO DA REDE
# ============================================================

etapa "CONFIGURANDO REDE"

# O arquivo já existe normalmente em instalações Ubuntu
# Server com cloud-init.
#
# Fazemos backup antes de substituir o conteúdo.

backup_arquivo /etc/netplan/50-cloud-init.yaml


cat > /etc/netplan/50-cloud-init.yaml <<EOF
network:
  version: 2

  ethernets:

    $INTERFACE_EXTERNA:
      dhcp4: true

    $INTERFACE_INTERNA:
      dhcp4: false

      addresses:
        - $IP_SERVIDOR/16

      nameservers:
        addresses:
          - $IP_SERVIDOR
EOF


chmod 600 /etc/netplan/50-cloud-init.yaml

netplan apply


# ============================================================
# 8. DHCP
# ============================================================

etapa "INSTALANDO E CONFIGURANDO DHCP"

apt install isc-dhcp-server -y


# ------------------------------------------------------------
# Parar o serviço antes de alterar sua configuração
# ------------------------------------------------------------

systemctl stop isc-dhcp-server


# ------------------------------------------------------------
# Backup do dhcpd.conf
# ------------------------------------------------------------

backup_arquivo /etc/dhcp/dhcpd.conf


# ------------------------------------------------------------
# Configuração DHCP
# ------------------------------------------------------------

cat > /etc/dhcp/dhcpd.conf <<EOF

# ============================================================
# DHCP - REDE CREFISA
# ============================================================

default-lease-time 600;
max-lease-time 7200;

authoritative;


subnet 172.20.0.0 netmask 255.255.0.0 {

    range $DHCP_INICIO $DHCP_FIM;

    option subnet-mask 255.255.0.0;

    option routers $IP_SERVIDOR;

    option broadcast-address 172.20.255.255;

    option domain-name "$DOMINIO";

    option domain-name-servers $IP_SERVIDOR;

    default-lease-time 600;

    max-lease-time 7200;
}
EOF


# ------------------------------------------------------------
# Configuração da interface utilizada pelo DHCP
# ------------------------------------------------------------

backup_arquivo /etc/default/isc-dhcp-server


cat > /etc/default/isc-dhcp-server <<EOF
INTERFACESv4="$INTERFACE_INTERNA"

#INTERFACESv6=""
EOF


# ------------------------------------------------------------
# Iniciar, reiniciar e habilitar DHCP
# ------------------------------------------------------------

systemctl start isc-dhcp-server

systemctl restart isc-dhcp-server

systemctl enable isc-dhcp-server


# ============================================================
# 9. DNS / BIND9
# ============================================================

etapa "INSTALANDO E CONFIGURANDO DNS / BIND9"

apt install bind9 bind9utils bind9-doc dnsutils -y


# ------------------------------------------------------------
# Parar BIND antes da configuração
# ------------------------------------------------------------

systemctl stop bind9


# ============================================================
# named.conf.options
# ============================================================

backup_arquivo /etc/bind/named.conf.options


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


# ============================================================
# named.conf.local
# ============================================================

backup_arquivo /etc/bind/named.conf.local


cat > /etc/bind/named.conf.local <<EOF

zone "$DOMINIO" IN {

    type master;

    file "/etc/bind/forward.$DOMINIO";

    allow-update { none; };

};


zone "20.172.in-addr.arpa" IN {

    type master;

    file "/etc/bind/reverse.$DOMINIO";

    allow-update { none; };

};
EOF


# ============================================================
# ZONA DIRETA
# ============================================================

# Este arquivo será criado pelo script.
# Se já existir, fazemos backup antes de substituí-lo.

backup_arquivo "/etc/bind/forward.$DOMINIO"


cat > "/etc/bind/forward.$DOMINIO" <<EOF
\$TTL 604800

@ IN SOA primary.$DOMINIO. root.$DOMINIO. (

    2026100201
    3600
    1800
    604800
    86400

)


; Servidor DNS

@       IN NS primary.$DOMINIO.


; Endereço do servidor DNS

primary IN A $IP_SERVIDOR


; Site da Crefisa

www     IN A $IP_SERVIDOR


; Nome do servidor

server  IN A $IP_SERVIDOR

EOF


# ============================================================
# ZONA REVERSA
# ============================================================

backup_arquivo "/etc/bind/reverse.$DOMINIO"


cat > "/etc/bind/reverse.$DOMINIO" <<EOF
\$TTL 86400

@ IN SOA primary.$DOMINIO. root.$DOMINIO. (

    2026100201
    3600
    1800
    604800
    86400

)


@ IN NS primary.$DOMINIO.


primary IN A $IP_SERVIDOR


1.0 IN PTR primary.$DOMINIO.

1.0 IN PTR www.$DOMINIO.

1.0 IN PTR server.$DOMINIO.

EOF


# ============================================================
# CONFIGURAÇÃO IPv4 DO BIND
# ============================================================

if [ -f /etc/default/named ]; then

    backup_arquivo /etc/default/named

else

    echo "/etc/default/named não existe."
    echo "O arquivo será criado."

fi


# Remove uma possível configuração OPTIONS anterior

sed -i '/^OPTIONS=/d' /etc/default/named 2>/dev/null


echo 'OPTIONS="-u bind -4"' >> /etc/default/named


# ============================================================
# TESTES DO DNS ANTES DE INICIAR
# ============================================================

echo
echo "Verificando configuração do BIND..."

named-checkconf

if [ $? -ne 0 ]; then

    echo
    echo "ERRO: named-checkconf encontrou problemas."
    exit 1

fi


named-checkzone \
    "$DOMINIO" \
    "/etc/bind/forward.$DOMINIO"


if [ $? -ne 0 ]; then

    echo
    echo "ERRO: zona direta inválida."
    exit 1

fi


named-checkzone \
    "20.172.in-addr.arpa" \
    "/etc/bind/reverse.$DOMINIO"


if [ $? -ne 0 ]; then

    echo
    echo "ERRO: zona reversa inválida."
    exit 1

fi


# ------------------------------------------------------------
# Iniciar, reiniciar e habilitar BIND
# ------------------------------------------------------------

systemctl start bind9

systemctl restart bind9

systemctl enable bind9


# ============================================================
# 10. APACHE
# ============================================================

etapa "INSTALANDO E CONFIGURANDO APACHE"

apt install apache2 -y


# ------------------------------------------------------------
# Parar Apache antes de alterar a página
# ------------------------------------------------------------

systemctl stop apache2


# ------------------------------------------------------------
# Backup da página original
# ------------------------------------------------------------

backup_arquivo /var/www/html/index.html


# ============================================================
# PÁGINA HTML DA CREFISA
# ============================================================

cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>

<html lang="pt-BR">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>Crefisa | Página de Teste</title>


    <style>

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }


        body {

            min-height: 100vh;

            display: flex;

            align-items: center;

            justify-content: center;

            font-family:
                Arial,
                Helvetica,
                sans-serif;

            background:

                radial-gradient(
                    circle at top left,
                    #00a7b5,
                    transparent 40%
                ),

                radial-gradient(
                    circle at bottom right,
                    #003b70,
                    transparent 45%
                ),

                linear-gradient(
                    135deg,
                    #e9fbff,
                    #ffffff
                );

            color: #123;

        }


        .container {

            width: min(900px, 90%);

            padding: 55px 45px;

            text-align: center;

            background:
                rgba(255,255,255,0.94);

            border-radius: 28px;

            box-shadow:
                0 25px 70px
                rgba(0,0,0,0.18);

            border:
                1px solid
                rgba(255,255,255,0.8);

        }


        .logo {

            width: 300px;

            max-width: 80%;

            margin-bottom: 30px;

        }


        h1 {

            font-size: 42px;

            margin-bottom: 15px;

            color: #003b70;

        }


        .subtitle {

            font-size: 22px;

            color: #008c9e;

            margin-bottom: 35px;

        }


        .info {

            display: grid;

            gap: 18px;

            margin-top: 25px;

        }


        .card {

            padding: 20px;

            border-radius: 15px;

            background: #f4fbfd;

            border-left:
                5px solid #00a7b5;

        }


        .label {

            font-size: 13px;

            text-transform: uppercase;

            letter-spacing: 1px;

            color: #607d8b;

            margin-bottom: 6px;

        }


        .value {

            font-size: 19px;

            font-weight: bold;

            color: #003b70;

        }


        .status {

            display: inline-flex;

            align-items: center;

            gap: 8px;

            margin-top: 25px;

            padding: 10px 18px;

            border-radius: 50px;

            background: #e7f8ef;

            color: #16794c;

            font-weight: bold;

        }


        .dot {

            width: 10px;

            height: 10px;

            border-radius: 50%;

            background: #21a366;

        }


        footer {

            margin-top: 35px;

            font-size: 14px;

            color: #78909c;

        }


        @media (max-width: 600px) {

            .container {

                padding: 35px 20px;

            }


            h1 {

                font-size: 32px;

            }


            .subtitle {

                font-size: 18px;

            }

        }

    </style>

</head>


<body>


    <main class="container">


        <!-- =================================================
             LOGO CREFISA
             ================================================= -->

        <svg class="logo"
             viewBox="0 0 500 193"
             xmlns="http://www.w3.org/2000/svg"
             role="img"
             aria-label="Crefisa">


            <defs>

                <linearGradient
                    id="bg"
                    x1="0"
                    y1="0"
                    x2="1"
                    y2="1">

                    <stop
                        offset="0%"
                        stop-color="#00a7b5"/>

                    <stop
                        offset="100%"
                        stop-color="#00649b"/>

                </linearGradient>

            </defs>


            <rect
                x="0"
                y="0"
                width="500"
                height="193"
                rx="30"
                fill="url(#bg)"
            />


            <circle
                cx="390"
                cy="62"
                r="22"
                fill="#f5b400"
            />


            <g
                stroke="#f5b400"
                stroke-width="7"
                stroke-linecap="round">

                <line
                    x1="390"
                    y1="27"
                    x2="390"
                    y2="15"/>

                <line
                    x1="390"
                    y1="99"
                    x2="390"
                    y2="111"/>

                <line
                    x1="355"
                    y1="62"
                    x2="343"
                    y2="62"/>

                <line
                    x1="425"
                    y1="62"
                    x2="437"
                    y2="62"/>

            </g>


            <text
                x="250"
                y="125"
                text-anchor="middle"
                font-family="Arial, Helvetica, sans-serif"
                font-size="85"
                font-weight="bold"
                font-style="italic"
                fill="white">

                crefisa

            </text>

        </svg>


        <h1>
            Página de Teste
        </h1>


        <p class="subtitle">
            Servidor Apache funcionando corretamente
        </p>


        <section class="info">


            <div class="card">

                <div class="label">
                    Curso
                </div>

                <div class="value">
                    Administrador de Servidores Linux
                </div>

            </div>


            <div class="card">

                <div class="label">
                    Instituição
                </div>

                <div class="value">
                    Senai Professor Vicente Amato<br>
                    Jandira/SP
                </div>

            </div>


            <div class="card">

                <div class="label">
                    Professor responsável
                </div>

                <div class="value">
                    André Bagnoli
                </div>

            </div>


        </section>


        <div class="status">

            <span class="dot"></span>

            Servidor online

        </div>


        <footer>

            Laboratório de Integração de Serviços Linux

        </footer>


    </main>


</body>

</html>
EOF


# ------------------------------------------------------------
# Iniciar, reiniciar e habilitar Apache
# ------------------------------------------------------------

systemctl start apache2

systemctl restart apache2

systemctl enable apache2


# ============================================================
# 11. SAMBA
# ============================================================

etapa "INSTALANDO E CONFIGURANDO SAMBA"

apt install samba -y


# ------------------------------------------------------------
# Parar Samba antes de alterar configuração
# ------------------------------------------------------------

systemctl stop smbd


# ------------------------------------------------------------
# Backup do smb.conf
# ------------------------------------------------------------

backup_arquivo /etc/samba/smb.conf


# ============================================================
# CRIAÇÃO DOS GRUPOS
# ============================================================

if ! getent group "$GRUPO_ADM" > /dev/null; then

    groupadd "$GRUPO_ADM"

fi


if ! getent group "$GRUPO_COMPRAS" > /dev/null; then

    groupadd "$GRUPO_COMPRAS"

fi


# ============================================================
# CRIAÇÃO DOS USUÁRIOS
# ============================================================

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


# ============================================================
# ASSOCIAR USUÁRIOS AOS GRUPOS
# ============================================================

usermod -aG "$GRUPO_ADM" "$USUARIO_ADM"

usermod -aG "$GRUPO_COMPRAS" "$USUARIO_COMPRAS"


# ============================================================
# SENHAS DO SAMBA
# ============================================================

printf "%s\n%s\n" \
    "$SENHA_ADM" \
    "$SENHA_ADM" \
    | smbpasswd -a -s "$USUARIO_ADM"


printf "%s\n%s\n" \
    "$SENHA_COMPRAS" \
    "$SENHA_COMPRAS" \
    | smbpasswd -a -s "$USUARIO_COMPRAS"


# ============================================================
# DIRETÓRIOS
# ============================================================

mkdir -p /srv/samba/administrativo

mkdir -p /srv/samba/compras


# ============================================================
# PERMISSÕES
# ============================================================

chown -R root:"$GRUPO_ADM" \
    /srv/samba/administrativo

chmod -R 2775 \
    /srv/samba/administrativo


chown -R root:"$GRUPO_COMPRAS" \
    /srv/samba/compras

chmod -R 2775 \
    /srv/samba/compras


# ============================================================
# CONFIGURAÇÃO DO SAMBA
# ============================================================

cat >> /etc/samba/smb.conf <<EOF


# ============================================================
# COMPARTILHAMENTO ADMINISTRATIVO
# ============================================================

[administrativo]

    path = /srv/samba/administrativo

    browseable = yes

    read only = no

    valid users = @$GRUPO_ADM

    force group = $GRUPO_ADM

    create mask = 0664

    directory mask = 2775


# ============================================================
# COMPARTILHAMENTO COMPRAS
# ============================================================

[compras]

    path = /srv/samba/compras

    browseable = yes

    read only = no

    valid users = @$GRUPO_COMPRAS

    force group = $GRUPO_COMPRAS

    create mask = 0664

    directory mask = 2775

EOF


# ============================================================
# TESTE DA CONFIGURAÇÃO DO SAMBA
# ============================================================

testparm -s


if [ $? -ne 0 ]; then

    echo
    echo "ERRO: configuração do Samba inválida."
    exit 1

fi


# ============================================================
# INICIAR, REINICIAR E HABILITAR SAMBA
# ============================================================

systemctl start smbd

systemctl restart smbd

systemctl enable smbd


# ============================================================
# 12. IP FORWARD + NAT
#
# ESTA É A ÚNICA PARTE DO SCRIPT ONDE UTILIZAMOS
# sudo su ANTES DAS ALTERAÇÕES.
# ============================================================

etapa "CONFIGURANDO IP FORWARD E NAT"

sudo su <<'NAT_CONFIG'

# ------------------------------------------------------------
# Ativa o encaminhamento IPv4
# ------------------------------------------------------------

echo 1 > /proc/sys/net/ipv4/ip_forward


# ------------------------------------------------------------
# NAT para a rede interna
#
# enp0s3 = interface que possui acesso à Internet
# 172.20.0.0/16 = rede interna dos clientes
# ------------------------------------------------------------

iptables -t nat -A POSTROUTING \
    -o enp0s3 \
    -s 172.20.0.0/16 \
    -j MASQUERADE

NAT_CONFIG


# ============================================================
# 13. STATUS DOS SERVIÇOS
# ============================================================

etapa "VERIFICANDO SERVIÇOS"

echo "DHCP:"
systemctl status isc-dhcp-server --no-pager

echo
echo "BIND9:"
systemctl status bind9 --no-pager

echo
echo "APACHE:"
systemctl status apache2 --no-pager

echo
echo "SAMBA:"
systemctl status smbd --no-pager


# ============================================================
# 14. TESTE DNS
# ============================================================

etapa "TESTANDO DNS"

if command -v dig > /dev/null 2>&1; then

    dig @"$IP_SERVIDOR" "www.$DOMINIO"

fi


# ============================================================
# 15. TESTE DO APACHE LOCALMENTE
# ============================================================

etapa "TESTANDO APACHE"

if command -v curl > /dev/null 2>&1; then

    curl -I "http://$IP_SERVIDOR"

fi


# ============================================================
# 16. REGRAS ATUAIS DO IPTABLES
# ============================================================

etapa "VERIFICANDO IPTABLES"

sudo su <<'IPTABLES_STATUS'

iptables -L INPUT -n --line-numbers

echo

iptables -t nat -L POSTROUTING -n --line-numbers

IPTABLES_STATUS


# ============================================================
# 17. INFORMAÇÕES FINAIS
# ============================================================

etapa "CONFIGURAÇÃO CONCLUÍDA"

echo
echo "============================================================"
echo "             SERVIDOR CREFISA CONFIGURADO"
echo "============================================================"
echo

echo "IP do servidor:"
echo "  $IP_SERVIDOR"

echo

echo "Rede:"
echo "  172.20.0.0/16"

echo

echo "DNS:"
echo "  $IP_SERVIDOR"

echo

echo "Domínio:"
echo "  $DOMINIO"

echo

echo "Site:"
echo "  http://www.$DOMINIO"

echo

echo "Site pelo IP:"
echo "  http://$IP_SERVIDOR"

echo

echo "Samba - Administrativo:"
echo "  \\\\$IP_SERVIDOR\\administrativo"

echo

echo "Samba - Compras:"
echo "  \\\\$IP_SERVIDOR\\compras"

echo

echo "Usuário administrativo:"
echo "  $USUARIO_ADM"

echo

echo "Usuário compras:"
echo "  $USUARIO_COMPRAS"

echo

echo "============================================================"
echo " BACKUPS DOS ARQUIVOS ORIGINAIS TERMINAM EM .bkp"
echo "============================================================"
echo

echo "Exemplo:"
echo "  /etc/samba/smb.conf"
echo "  /etc/samba/smb.conf.bkp"

echo

echo "============================================================"
echo " ATENÇÃO: NTP NÃO FOI CONFIGURADO"
echo "============================================================"
echo
echo "O material de apoio fornecido não possui comandos"
echo "de instalação/configuração do servidor NTP."
echo
echo "Por isso ele não foi inventado ou incluído neste script."
echo

echo "============================================================"
echo " FIM DO SCRIPT"
echo "============================================================"
```
