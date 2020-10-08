##############################################################################
# Instalação e Configuração Inicial
##############################################################################

# Atualizar repositórios:

yum repolist


# Instalação de pacotes necessários:

yum groupinstall -y "Development Tools"

yum install -y git postgresql10-devel.x86_64 gcc make\
 {readline,libxslt,libselinux,pam,openssl}-devel



# Clonando o repositório:

git clone https://github.com/2ndQuadrant/repmgr.git /tmp/repmgr


# Ir para o diretório do repositório e instalar via compilação:

cd /tmp/repmgr

./configure && make && make install



# Criação do arquivo de serviço do repmgrd:

cat << EOF > /lib/systemd/system/repmgrd.service
[Unit]
Description=A replication manager, and failover management tool for PostgreSQL
After=syslog.target
After=network.target
After=postgresql-12.service

[Service]
Type=forking

User=postgres
Group=postgres

PIDFile=/var/run/repmgr/repmgrd.pid

# Where to send early-startup messages from the server 
# This is normally controlled by the global default set by systemd
# StandardOutput=syslog
ExecStart=/usr/local/pgsql/12/bin/repmgrd \
-f /etc/repmgr/repmgr.conf -p /var/run/repmgr/repmgrd.pid -d --verbose
ExecStop=kill -TERM \`cat /var/run/repmgr/repmgrd.pid\`
ExecReload=kill -HUP \`cat /var/run/repmgr/repmgrd.pid\`

# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF



# Habilitando o serviço repmgrd:

systemctl enable repmgrd.service



# Criação de arquivo para criação de diretório temporário para arquivo de pid:

cat << EOF > /usr/lib/tmpfiles.d/repmgr.conf
d /var/run/repmgr 0755 postgres postgres -
EOF



# Cria o diretório temporário:

systemd-tmpfiles --create



# Variável de ambiente para o Node ID:

read -p 'Digite o ID do nó: ' NODEID



# Criação do arquivo principal do repmgr:

cat << EOF > /etc/repmgr/repmgr.conf && \
chown postgres: /etc/repmgr/repmgr.conf
node_id=${NODEID}
node_name=`hostname`
conninfo='host=`hostname` user=rep_teste dbname=db_repmgr\
 connect_timeout=2'
data_directory='/var/local/pgsql/data'
pg_bindir='/usr/pgsql-12/bin'
replication_type='physical'
use_replication_slots='yes'
witness_sync_interval=15

# repmgrd
failover=automatic
promote_command='/usr/local/pgsql/12/bin/repmgr standby promote\
 -f /etc/repmgr/repmgr.conf --log-to-file'
follow_command='/usr/local/pgsql/12/bin/repmgr standby follow\
 -f /etc/repmgr/repmgr.conf --log-to-file --upstream-node-id=%n'

# Log
log_level=INFO
log_file=/var/log/pg_log/pro_teste/repmgrd.log
log_status_interval=300
EOF



# Arquivo pg_hba.conf:

cat << EOF > ${PGDATA}/pg_hba.conf && pg_ctl reload
local  all  all  trust
host   all  all  127.0.0.1/32  trust
host   all  all  ::1/128       trust

host  db_teste  user_teste  192.168.56.2/32 trust
host  db_teste  user_teste  192.168.56.3/32 trust
host  db_teste  user_teste  192.168.56.4/32 trust
host  db_teste  user_teste  192.168.56.5/32 trust

host  db_repmgr  rep_teste  192.168.56.2/32 trust
host  db_repmgr  rep_teste  192.168.56.3/32 trust
host  db_repmgr  rep_teste  192.168.56.4/32 trust
host  db_repmgr  rep_teste  192.168.56.5/32 trust

host  replication  rep_teste  192.168.56.2/32 trust
host  replication  rep_teste  192.168.56.3/32 trust
host  replication  rep_teste  192.168.56.4/32 trust
host  replication  rep_teste  192.168.56.5/32 trust

host    db_teste       user_teste  192.168.0.174/32      md5
host    db_teste       user_teste  192.168.0.175/32      md5
host    db_teste       user_teste  192.168.0.176/32      md5
EOF


cat << EOF >> ${PGDATA}/pg_hba.conf && pg_ctl reload

host  db_repmgr  rep_teste  192.168.56.2/32  trust
host  db_repmgr  rep_teste  192.168.56.3/32  trust
host  db_repmgr  rep_teste  192.168.56.4/32  trust
host  db_repmgr  rep_teste  192.168.56.5/32  trust
EOF






##############################################################################
# Configuração do Nó Primário
##############################################################################

# Alterar os seguintes parâmetros do postgresql.conf:

'
max_wal_senders = 10
wal_level = 'logical'
hot_standby = on
archive_mode = on
archive_command = '/bin/true'
wal_keep_segments = 0
max_replication_slots = 10
hot_standby_feedback = on
'



# Criar role e database para o repmgr:

psql << EOF
CREATE ROLE rep_teste
    REPLICATION
    LOGIN
    SUPERUSER
    ENCRYPTED PASSWORD '123';
CREATE DATABASE db_repmgr OWNER rep_teste;
EOF



# Registrar o nó como primário:

repmgr -f /etc/repmgr/repmgr.conf primary register



# Tabela de histórico de monitoramento como UNLOGGED:

psql -c 'ALTER TABLE repmgr.monitoring_history SET UNLOGGED;'\
 -U rep_teste db_repmgr



# Exibir informações do cluster:

repmgr -f /etc/repmgr/repmgr.conf cluster show

'
 ID | Name         | Role    | Status    | Upstream | Location | Connection string                                                      
----+--------------+---------+-----------+----------+----------+-------------------------------------------------------------------------
 1  | pghost04 | primary | * running |          | default  | host=pghost04 user=rep_teste dbname=db_repmgr connect_timeout=2
'



# Exibir informações do cluster via query:

psql -qc 'SELECT * FROM repmgr.nodes;' -U rep_teste db_repmgr

'
-[ RECORD 1 ]----+------------------------------------------------------------------------
node_id          | 1
upstream_node_id | 
active           | t
node_name        | pghost04
type             | primary
location         | default
priority         | 100
conninfo         | host=pghost04 user=rep_teste dbname=db_repmgr connect_timeout=2
repluser         | rep_teste
slot_name        | repmgr_slot_1
config_file      | /etc/repmgr/repmgr.conf
'



##############################################################################
# Configuração de Standbys
##############################################################################



# Parando o serviço do PostgreSQL:

pg_ctl stop



# Antes de clonar o nó primário, fazer teste com a opção --dry-run:

repmgr -h pghost04 -U rep_teste -d db_repmgr\
 -f /etc/repmgr/repmgr.conf standby clone --dry-run

'
NOTICE: destination directory "/var/local/pgsql/data" provided
ERROR: specified data directory "/var/local/pgsql/data" appears to contain a running PostgreSQL instance
HINT: ensure the target data directory does not contain a running PostgreSQL instance

# Para clonar o nó primário é necessário que o PGDATA esteja vazio
'



# Criando diretório de backup para neste momento copiar os arquivos de
# configuração e logo em seguida copiá-los:

mkdir /var/local/pgsql/bkp

cp ${PGDATA}/*.conf /var/local/pgsql/bkp/



# Apagando o conteúdo de diretórios PGDATA e de tablespaces:

rm -fr $PGDATA/*

rm -fr /var/local/pgsql/ts/index/*



# Clonagem do nó primário:

repmgr -h pghost04 -U rep_teste -d db_repmgr\
 -f /etc/repmgr/repmgr.conf standby clone



# Copiando os arquivos de configuração originais para o PGDATA:

cp /var/local/pgsql/bkp/*.conf ${PGDATA}/



# Iniciando o serviço do PostgreSQL no nó:

pg_ctl start



# Registrando o nó como standby:

repmgr -f /etc/repmgr/repmgr.conf standby register



# Para testar a replicação, no nó primário, crie alguma base de dados de
# teste, dê o comando abaixo (standby), apague essa base e repita o comando
# no standby:

cat << EOF | psql -Atq
SELECT datname FROM pg_database
 WHERE datname !~ 'postgres|template|repmgr';
EOF



##############################################################################
# Configuração do nó Witness
##############################################################################



# Criar role e database para o repmgr:

psql << EOF
CREATE ROLE rep_teste
    REPLICATION
    LOGIN
    SUPERUSER
    ENCRYPTED PASSWORD '123';
CREATE DATABASE db_repmgr OWNER rep_teste;
EOF



# Registrando o nó como witness:

repmgr -f /etc/repmgr/repmgr.conf witness register -h pghost04


##############################################################################
# Configuração do repmgrd
##############################################################################

# postgresql.conf

'
shared_preload_libraries = 'repmgr'
'


# repmgr.conf

'
failover=automatic
promote_command='/usr/local/pgsql/12/bin/repmgr standby promote -f /etc/repmgr/repmgr.conf --log-to-file'
follow_command='/usr/local/pgsql/12/bin/repmgr standby follow -f /etc/repmgr/repmgr.conf --log-to-file --upstream-node-id=%n'
'



# Iniciar o serviço em todos os nós do cluster:

systemctl start repmgrd



##############################################################################
# Failback
##############################################################################

cp ${PGDATA}/*.conf /var/local/pgsql/bkp/

repmgr node rejoin -d 'host=pghost05 user=rep_teste dbname=db_repmgr connect_timeout=2' --force-rewind

pg_ctl restart

repmgr -f /etc/repmgr/repmgr.conf standby switchover

# Todos

systemctl stop repmgrd


# Primário e witness:

su - postgres -c "psql -c 'DROP DATABASE db_repmgr;'"

su - postgres -c "psql -c 'CREATE DATABASE db_repmgr OWNER rep_teste;'"


# Registrar o nó como primário:

repmgr -f /etc/repmgr/repmgr.conf primary register



# Registrando o nó como standby:

repmgr -f /etc/repmgr/repmgr.conf standby register


# Registrando o nó como witness:

repmgr -f /etc/repmgr/repmgr.conf witness register -h pghost04



# Todos

systemctl start repmgrd


Obs.:

O nó que tinha virado primário na falha que houve passou a ser seguido por
outros nós standbys e ao fazer o processo de failover eles ainda não seguem o
nó primário inicial.
É preciso fazer com que sigam o novo master, senão a replicação fica cascateada.

repmgr -f /etc/repmgr/repmgr.conf standby unregister

pg_ctl stop

repmgr node rejoin -d 'host=pghost04 user=rep_teste dbname=db_repmgr connect_timeout=2' --force-rewind

pg_ctl start

repmgr -Ff /etc/repmgr/repmgr.conf standby register



##############################################################################
# Desativar o repmgr
##############################################################################

systemctl disable repmgrd

su - postgres -c "psql -c 'DROP DATABASE db_repmgr;'"
su - postgres -c "psql -c 'DROP ROLE rep_teste;'"
