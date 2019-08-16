#!/bin/bash

"
docker run -itd \
    --hostname minio.local \
    --name minio \
    --network net_curso \
    -p 9000:9000 \
    -e 'MINIO_ACCESS_KEY=5D0EN4B8SF7EYUJH1V8I' \
    -e 'MINIO_SECRET_KEY=BjtgRNuLHBSEUU4e2Yzz/lBVjoFVnIvCr6rGFRXo' \
    minio/minio \
    server /data
"

# Baixando o Minio

wget https://dl.minio.io/server/minio/release/linux-amd64/minio \
    -P /usr/local/bin/

# Permissão de execução

chmod 755 /usr/local/bin/minio

# Ajustes de firewall

firewall-cmd --zone=public --add-port=9000/tcp --permanent

firewall-cmd --reload

# 

cat << EOF > /etc/default/minio
MINIO_VOLUMES='/var/local/minio/data'
MINIO_OPTS='--address :9000'
MINIO_ACCESS_KEY=5D0EN4B8SF7EYUJH1V8I
MINIO_SECRET_KEY=BjtgRNuLHBSEUU4e2Yzz/lBVjoFVnIvCr6rGFRXo

export MINIO_VOLUMES MINIO_OPTS MINIO_ACCESS_KEY MINIO_SECRET_KEY
EOF

# Carregando as variáveis

source /etc/default/minio

# Criação de grupo e usuário

groupadd -r minio

useradd -r -k /etc/skel -s /bin/bash -md /var/local/minio -g minio minio

# Usuário minio lê variáveis de ambiente ao fazer login

echo 'source /etc/default/minio' >> ~minio/.bashrc

# Criando o diretório de dados

su - minio -c 'mkdir ${MINIO_VOLUMES}'

# Testando...

su - minio -c 'minio server ${MINIO_VOLUMES}' &

# Parando o serviço

su - minio -c 'killall minio'

# Criação do Unit file do SystemD:

cat << EOF > /etc/systemd/system/minio.service
Description=Minio
Documentation=https://docs.minio.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio
 
[Service]
WorkingDirectory=${MINIO_VOLUMES}
 
User=minio
Group=minio
 
PermissionsStartOnly=true
 
EnvironmentFile=-/etc/default/minio
ExecStartPre=/bin/bash -c "[ -n \"${MINIO_VOLUMES}\" ] || echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\""
 
ExecStart=/usr/local/bin/minio server \$MINIO_OPTS \$MINIO_VOLUMES
 
StandardOutput=journal
StandardError=inherit
 
# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536
 
# Disable timeout logic and wait until process is stopped
TimeoutStopSec=0
 
# SIGTERM signal is used to stop Minio
KillSignal=SIGTERM
 
SendSIGKILL=no
 
SuccessExitStatus=0
 
[Install]
WantedBy=multi-user.target
EOF

# Habilitando e iniciando o serviço na inicialização

systemctl enable --now minio


# 
# CONFIGURAÇÃO TLS1
# https://docs.minio.io/docs/how-to-secure-access-to-minio-server-with-tls.html

# Gerar a chave primária (RSA):

su - minio -c 'openssl genrsa -out ~/.minio/private.key 2048'

# 

cat << EOF > ~minio/.minio/openssl.conf && \
chown minio: ~minio/.minio/openssl.conf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = BR
ST = SP
L = SAO PAULO
O = FOO CORPORATION
OU = TI
CN = minio

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = 192.168.56.2
EOF


# Gerar certificado auto assinado:

su - minio -c '
openssl \
    req -x509\
    -nodes\
    -days 730\
    -newkey rsa:2048\
    -keyout ~/.minio/certs/private.key\
    -out ~/.minio/certs/public.crt\
    -config ~/.minio/openssl.conf'

# ============================================================================
# Distribuído
# ============================================================================

# Domínio:

read -p 'Domínio: ' MINIO_DOMAIN



sed "s:\(MINIO_SECRET_KEY=.*\):\1\nMINIO_DOMAIN=${MINIO_DOMAIN}:g" \
    -i /etc/default/minio 



sed 's:\(export.*\):\1 MINIO_DOMAIN:g' -i /etc/default/minio 

read -p 'Quantos nós terá o cluster? ' N_NODES

unset MINIO_VOLUMES

for i in `seq 1 ${N_NODES}`;
do
    read -p "Digite o node ${1} no formato: \
<http ou https>://<hostname ou IP>:<porta>/<storage> " MINIO_VOLUMES[$((i-1))]
done

export MINIO_VOLUMES="${MINIO_VOLUMES[@]}"




