# [root] Digite a versão majoritária do PostgreSQL:
read -p '# Digite a versão majoritária do PostgreSQL: ' PG_VERSION

# [root] PGDATA:
export PGDATA="/var/lib/postgresql/${PG_VERSION}/main"

# Pacotes necessários:
export PKG="\
postgresql-server-dev-${PG_VERSION} \
make
flex \
libxslt1-dev \
libxml2-dev \
libselinux1-dev \
libpam0g-dev \
libssl-dev \
libkrb5-dev \
libedit-dev \
zlib1g-dev \
libreadline-dev
"

# Instalação dos pacotes:
apt install -y ${PKG}

# [root] Digite a versão (X.Y.Z) do repmgr a ser baixada:
read -p 'Digite a versão (X.Y.Z) do repmgr a ser baixada: ' REPMGR_VERSION

# [root] URL do arquivo do repmgr
export REPMGR_URL="https://repmgr.org/download/repmgr-${REPMGR_VERSION}.tar.gz"

# Baixar o repmgr:
wget -c ${REPMGR_URL} -P /tmp/

# [root] Ir ao diretório onde o arquivo foi baixado, descompactá-lo e acessar o diretório:
cd /tmp/ && tar xvf repmgr-${REPMGR_VERSION}.tar.gz && cd repmgr-${REPMGR_VERSION}

# [root] Compilação:
./configure && make && make install

# [root] Após a compilação ter sido bem sucedida, remover os pacotes instalados:
apt purge -y ${PKG}



# Criação do diretório de configuração e de logs do repmgr:
mkdir -m 744 {/etc,/var/log}/repmgr

# [root] Variável de ambiente para o Node ID (inteiro maior que zero):

read -p 'Digite o ID do nó: ' NODEID

# [root] Criação do arquivo principal do repmgr:

cat << EOF > /etc/repmgr/repmgr.conf
node_id=${NODEID}
node_name='`hostname -s`'
conninfo='host=`hostname -s` user=user_repmgr dbname=db_repmgr\
 connect_timeout=2'
data_directory='${PGDATA}'
pg_bindir='/usr/lib/postgresql/${PG_VERSION}/bin'
use_replication_slots='yes'
witness_sync_interval=15
# repmgrd
failover=automatic
promote_command='/usr/lib/postgresql/${PG_VERSION}/bin/repmgr standby promote\
 -f /etc/repmgr/repmgr.conf --log-to-file'
follow_command='/usr/lib/postgresql/${PG_VERSION}/bin/repmgr standby follow\
 -f /etc/repmgr/repmgr.conf --log-to-file --upstream-node-id=%n'
# Log
log_level=INFO
log_file='/var/log/repmgr/repmgrd.log'
log_status_interval=300
EOF


# [root] Criação do arquivo de serviço do repmgrd:
cat << EOF > /lib/systemd/system/repmgrd.service
[Unit]
Description=A replication manager, and failover management tool for PostgreSQL
After=syslog.target
After=network.target
After=postgresql.service
[Service]
Type=forking
User=postgres
Group=postgres
PIDFile=/var/run/repmgr/repmgrd.pid
# Where to send early-startup messages from the server 
# This is normally controlled by the global default set by systemd
# StandardOutput=syslog
ExecStart=/usr/lib/postgresql/${PG_VERSION}/bin/repmgrd \
-f /etc/repmgr/repmgr.conf -p /var/run/repmgr/repmgrd.pid -d --verbose
ExecStop=kill -TERM \`cat /var/run/repmgr/repmgrd.pid\`
ExecReload=kill -HUP \`cat /var/run/repmgr/repmgrd.pid\`
# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=300
[Install]
WantedBy=multi-user.target
EOF

# [root] Habilitando o serviço repmgrd:
systemctl enable repmgrd.service

# [root] Criação de arquivo para criação de diretório temporário para arquivo de pid:
cat << EOF > /usr/lib/tmpfiles.d/repmgr.conf
d /var/run/repmgr 0755 postgres postgres -
EOF

# [root] Cria o diretório temporário:
systemd-tmpfiles --create

# [root] IPs dos servidores do cluster: 
read -p 'Digite os IPs dos nós (separados por um espaço): ' IP

# [root] Adicionar linhas ao pg_hba.conf:
cat << EOF >> /etc/postgresql/${PG_VERSION}/main/pg_hba.conf

# REPMGR ======================================================================
# repmgr database
EOF

for i in ${IP}
do
	echo "host  db_repmgr  user_repmgr  ${i}/32 trust" >> \
		/etc/postgresql/${PG_VERSION}/main/pg_hba.conf
done

cat << EOF >> /etc/postgresql/${PG_VERSION}/main/pg_hba.conf

# Replication
EOF

for i in ${IP}
do
	echo "host  replication  user_repmgr  ${i}/32 trust" >> \
		/etc/postgresql/${PG_VERSION}/main/pg_hba.conf
done

cat << EOF >> /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
# =============================================================================
EOF

# Tornar o usuário postgres independente --------------------------------------
# [root] Criar arquivo de variáveis de ambiente
cat << EOF > ~postgres/.pgvars
export PG_VERSION='${PG_VERSION}'
export PGDATA="/var/lib/postgresql/\${PG_VERSION}/main"
export PGUSER='postgres'
export PGDATABASE='postgres'
export PGPORT='5432'
export PATH="/usr/lib/postgresql/\${PG_VERSION}/bin:\${PATH}"
EOF

# [root] Criar link de arquivos de configuração dentro de $PGDATA:
ls /etc/postgresql/${PG_VERSION}/main/*.conf | xargs -i ln -sf {} ${PGDATA}/

# [root] Copiar arquivos do diretório template:
cp -v /etc/skel/.* ~postgres/

# [root] Faz com que o arquivo de perfil leia o arquivo de variáveis ao logar:
echo -e "\nsource ~/.pgvars" >> ~postgres/.bashrc

# [root] Criar arquivo de perfil do psql:
cat << EOF > ~postgres/.psqlrc
\\x auto
\\set COMP_KEYWORD_CASE upper
\\set HISTCONTROL ignoreboth
EOF

# [root] Dar propriedade ao usuário e grupo postgres:
chown -R postgres: /etc/repmgr /var/log/repmgr ~postgres/

# ----------------------------------------------------------------------------

##############################################################################
# Configurações do nó primário
##############################################################################

# Alterar os seguintes parâmetros do postgresql.conf:

'
listen_addresses = '*'
wal_level = replica
archive_mode = on
archive_command = '/bin/true'
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
shared_preload_libraries = 'repmgr'
'

# [postgres] Criar role e database para o repmgr:
psql << EOF
CREATE ROLE user_repmgr
    REPLICATION
    LOGIN
    SUPERUSER;
CREATE DATABASE db_repmgr OWNER user_repmgr;
EOF

# [postgres] Registrar o nó como primário:
repmgr -f /etc/repmgr/repmgr.conf primary register

# [postgres] Verifique informações do cluster:
repmgr -f /etc/repmgr/repmgr.conf cluster show

'
 ID | Name            | Role    | Status    | Upstream | Location | Priority | Timeline | Connection string                                                       
----+-----------------+---------+-----------+----------+----------+----------+----------+--------------------------------------------------------------------------
 1  | postgres-master | primary | * running |          | default  | 100      | 1        | host=postgres-master user=user_repmgr dbname=db_repmgr connect_timeout=2
'

# [postgres] É possível obter a mesma informação via consulta no banco:
psql -qc 'SELECT * FROM repmgr.nodes;' -U user_repmgr db_repmgr

'
-[ RECORD 1 ]----+-------------------------------------------------------------------------
node_id          | 1
upstream_node_id | 
active           | t
node_name        | postgres-master
type             | primary
location         | default
priority         | 100
conninfo         | host=postgres-master user=user_repmgr dbname=db_repmgr connect_timeout=2
repluser         | user_repmgr
slot_name        | repmgr_slot_1
config_file      | /etc/repmgr/repmgr.conf
'

##############################################################################
# Configurações de standby
##############################################################################

# Pare o serviço do PostgreSQL:
pg_ctl stop

# Antes de clonar o nó primário, fazer teste com a opção --dry-run:
repmgr -h postgres-master -U user_repmgr -d db_repmgr\
 -f /etc/repmgr/repmgr.conf standby clone --dry-run

# Se o teste dry run deu certo, clone o nó primário: 
repmgr -h postgres-master -U user_repmgr -d db_repmgr\
 -f /etc/repmgr/repmgr.conf standby clone

# Inicie o serviço do PostgreSQL:
pg_ctl start

# Registrando o nó como standby:
repmgr -f /etc/repmgr/repmgr.conf standby register

##############################################################################
