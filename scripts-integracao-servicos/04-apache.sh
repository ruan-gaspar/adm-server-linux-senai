```bash
#!/bin/bash

# ============================================================
# 04 - APACHE
# ============================================================


if [ "$EUID" -ne 0 ]; then

    echo "Execute com sudo:"
    echo "sudo ./04-apache.sh"

    exit 1

fi


# ------------------------------------------------------------
# Instalação
# ------------------------------------------------------------

apt update

apt install apache2 -y


# ------------------------------------------------------------
# Parar Apache
# ------------------------------------------------------------

systemctl stop apache2


# ------------------------------------------------------------
# Backup da página original
# ------------------------------------------------------------

if [ -f /var/www/html/index.html ]; then

    cp /var/www/html/index.html \
       /var/www/html/index.html.bkp

fi


# ============================================================
# PÁGINA CREFISA
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

    color: #78909c;

}

</style>

</head>


<body>


<main class="container">


<svg class="logo"
viewBox="0 0 500 193"
xmlns="http://www.w3.org/2000/svg">


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


<text
x="250"
y="125"
text-anchor="middle"
font-family="Arial"
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


# ============================================================
# SERVIÇO
# ============================================================

systemctl start apache2

systemctl restart apache2

systemctl enable apache2


# ============================================================
# EVIDÊNCIAS
# ============================================================

echo
echo "============================================================"
echo " APACHE - CONFIGURAÇÃO"
echo "============================================================"


echo
echo "--- Arquivo da página ---"

cat /var/www/html/index.html


echo
echo "--- STATUS DO APACHE ---"

systemctl status apache2 --no-pager


echo
echo "--- TESTE HTTP ---"

curl -I http://172.20.0.1


echo
echo "============================================================"
echo " APACHE CONFIGURADO E ATIVO"
echo "============================================================"

echo
echo "Acesse no Windows:"
echo
echo "http://www.crefisa.local"

```
