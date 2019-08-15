##############################################################################
# CEPH CENTOS 7 - ÚNICO NÓ
##############################################################################


# - Ceph - Object Storage
#
# - Placement Groups - PG
# Quanto mais PGs, mais dados fragmentados, porém mais rápida a recuperação em caso de falha.
# cat >/etc/yum.repos.d/ceph.repoO número de PGs também afeta o desempenho do disco, então em casos que o cluster for pequeno,
# como no exemplo a seguir terá somente dois discos e uma única máquina, dê preferência a manter os valores padrão.
# 
# - OSD - Object Storage Device
#
# O Ceph é formado por 3 serviços: ceph-monitor (cmon), ceph-osd (cosd), e o ceph-admin (cmds).
#
# - Ceph-Monitor: Mantém uma cópia de como os dados estão armazenados dentro de seu cluster;
# - Ceph-OSD: Gerencia os nodes do seu cluster;
# - Ceph-admin: Administração do seu cluster.



## Instalação de Nó Único



# Instalação do repositório EPEL:

yum install -y epel-release



# Criação de grupo de sistema:

groupadd -r ceph



# Criação de usuário de sistema:

useradd -s /bin/bash -k /etc/skel -d /var/lib/ceph \
-g ceph -m -r ceph



#

su - ceph -c "ssh-keygen -t rsa -P '' \
-f ~/.ssh/id_rsa && \
cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys && \
chmod 600 ~/.ssh/* &&
ssh localhost -o StrictHostKeyChecking=no '/bin/true'"



# Importação das chaves de repositório:

rpm --import 'https://download.ceph.com/keys/release.asc'



# Verifique o nome do major release em http://docs.ceph.com/docs/mimic/releases/#id1
# Por exemplo, Luminous...



# De posse do nome do release, digite-o em lowercase após o comando:

read -p 'Digite o nome do release do Ceph em letras minúsculas: ' CEPH_RELEASE



# De posse da distro (el7, por exemplo):

read -p 'Digite o nome da distro CentOS: ' DISTRO



# Criação do arquivo de repositório do Ceph e atualizando a base de dados de
# pacotes:

cat << EOF > /etc/yum.repos.d/ceph.repo && yum repolist
[ceph]
name=Ceph packages for `arch`
baseurl=https://download.ceph.com/rpm-${CEPH_RELEASE}/${DISTRO}/`arch`
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-${CEPH_RELEASE}/${DISTRO}/noarch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://download.ceph.com/rpm-${CEPH_RELEASE}/${DISTRO}/SRPMS
enabled=0
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF



# Instalar o ceph-deploy na máquina, fazer a instalação e configuração do Ceph
# dentro de todas as máquinas do Cluster:

yum install -y ceph-deploy python-setuptools && yum clean all



# Visudo

visudo

'
ceph ALL=(ALL) NOPASSWD: ALL
'



# Para começar a instalação, inicialize o servidor atual como um node do Ceph através do comando ceph-deploy new <servidor> conforme abaixo:

su - ceph -c "ceph-deploy new `hostname`"



# Listando os arquivos gerados:

ls ~ceph/

'
ceph.conf  ceph-deploy-ceph.log  ceph.mon.keyring
'



# 

cat ~ceph/ceph.conf

'
fsid = 95f95e7b-f234-4af6-84bd-d23c366e3a68
mon_initial_members = ceph
mon_host = 192.168.56.2
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
'


# Apaga linhas em branco:

sed '/^\s*$/d' -i ~ceph/ceph.conf



# 

cat << EOF >> ~ceph/ceph.conf
osd pool default size = 1
osd crush chooseleaf type = 0
EOF


"
O que faz com que o Ceph possa trabalhar com um número limitado de máquinas é a opção osd crush chooseleaf type, que é usado pelo serviço de CRUSH do Ceph para decidir quais servidores os dados serão armazenados. Por se tratar de um ambiente mononode, basta colocar a opção como 0 que esse serviço será desabilitado.
"


# Alteração feita, agora basta instalar seus serviços na nossa única máquina através do comando ceph install conforme abaixo:

su - ceph -c "ceph-deploy install `hostname` --release ${CEPH_RELEASE}"

"
A opção –release serve para informarmos que queremos que seja feito a instalação da versão mais recente. Aguarde o término da instalação dos pacotes e configuração para que possamos criar o monitor. 
"



# O monitor será criado através do comando abaixo:

su - ceph -c 'ceph-deploy mon create-initial'



# Pronto! Feito isso temos um cluster de Ceph, porém não temos nenhum armazenamento para ele. Precisamos incluir os discos para que possamos começar a criar nossos PGs e começarmos a armazenar nossos dados. Para incluir os discos, supondo que eles se chamem sdb e sdc, execute o comando de preparação dos discos conforme abaixo:

ceph-deploy osd prepare localhost:sdb

ceph-deploy osd prepare localhost:sdc



















