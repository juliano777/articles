```bash
RH_VERSION=`grep -F 'VERSION_ID' /etc/os-release | \
    tr -d \" | cut -f2 -d= |  cut -f1 -d.`
```

```bash
URL="https://download.postgresql.org/pub/repos/yum/reporpms/\
EL-${RH_VERSION}-x86_64/pgdg-redhat-repo-latest.noarch.rpm"
```

```bash
dnf install -y ${URL}
```

```bash
dnf config-manager --set-enabled  pgdg-rhel${RH_VERSION}-extras
```

```bash
dnf install -y etcd && dnf clean all
```

```bash
etcd --version | head -1 | cut -f2 -d: | xargs
```
```
3.5.9
```

```bash
curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest | \
grep tag_name | cut -d '"' -f 4 | tr -d 'v'
```
```
3.5.9
```

```bash
firewall-cmd --quiet --zone=public --add-port=2379/tcp --permanent
firewall-cmd --quiet --zone=public --add-port=2380/tcp --permanent
firewall-cmd --quiet --reload
```


## Certificates


### Certificado de Autoridade de Certificação (CA):

mkdir -pm 0700 /etc/etcd/cert

Para gerar um certificado autoassinado para atuar como sua própria Autoridade de Certificação (CA), você pode usar ferramentas como OpenSSL.
Execute o seguinte comando para gerar uma chave privada para a CA:

```bash
openssl genpkey -algorithm RSA -out /etc/etcd/cert/ca.key
```

```bash
SUBJ="/C=$country/\
ST=$state/\
L=$locality/\
O=$organization/\
OU=$organizationalunit/\
CN=$commonname/\
emailAddress=$email"
```


```bash
openssl req -new -x509 \
   -key /etc/etcd/cert/ca.key \
   -out /etc/etcd/cert/ca.crt \
   -subj "${SUBJ}"

```

### Certificados e chaves para peers e clients:

Para cada peer e cliente que participará do cluster etcd, você precisará gerar um par de chave privada e certificado.
Execute o seguinte comando para gerar uma chave privada para um peer ou cliente:

```bash
openssl genpkey -algorithm RSA -out /etc/etcd/cert/peer.key
openssl genpkey -algorithm RSA -out /etc/etcd/cert/client.key
```

Em seguida, gere uma solicitação de assinatura de certificado (CSR - Certificate Signing Request) usando a chave privada:

```bash
openssl req -new -key /etc/etcd/cert/peer.key -out /etc/etcd/cert/peer.csr -subj "${SUBJ}"
openssl req -new -key /etc/etcd/cert/client.key -out /etc/etcd/cert/client.csr -subj "${SUBJ}"
```

Você precisará fornecer informações sobre o peer ou cliente ao preencher os detalhes solicitados.
Em seguida, assine o CSR com a chave privada da CA para obter o certificado:

```bash
openssl x509 -req -in /etc/etcd/cert/peer.csr -CA /etc/etcd/cert/ca.crt -CAkey /etc/etcd/cert/ca.key -CAcreateserial -out /etc/etcd/cert/peer.crt
openssl x509 -req -in /etc/etcd/cert/client.csr -CA /etc/etcd/cert/ca.crt -CAkey /etc/etcd/cert/ca.key -CAcreateserial -out /etc/etcd/cert/client.crt
```

chown -R etcd: /etc/etcd /var/lib/etcd
chmod 0700 /var/lib/etcd



Lembre-se de substituir <nome> pelo nome adequado para cada certificado e chave que você está gerando. Certifique-se de fornecer informações precisas e relevantes ao criar solicitações de assinatura de certificado (CSRs) para peers e clientes.

Esses comandos são apenas uma referência geral e podem precisar ser adaptados com base nas suas necessidades específicas e no ambiente em que você está trabalhando. Além disso, é importante seguir as melhores práticas de segurança ao gerar e armazenar esses arquivos sensíveis.

Após gerar os certificados e chaves, você poderá usá-los nos arquivos de configuração do etcd conforme mencionado anteriormente, substituindo as referências /path/to/ pelos caminhos reais onde você salvou os arquivos correspondentes.



## Configuration


```bash
mv /etc/etcd/etcd.conf /etc/etcd/etcd.conf.original
```



```bash
vim /etc/etcd/etcd.conf.yaml
```

```bash
systemctl edit --full etcd.service
```
```
ExecStart=/bin/bash -c "GOMAXPROCS=`nproc` /usr/bin/etcd --config-file /etc/etcd/etcd.conf.yaml"
```




```bash
systemctl enable --now etcd.service
```

```bash
systemctl status etcd
```
```
● etcd.service - Etcd Server
     Loaded: loaded (/usr/lib/systemd/system/etcd.service; enabled; preset: disabled)
     Active: active (running) since Wed 2023-06-07 12:05:01 -03; 39s ago
   Main PID: 19808 (etcd)
      Tasks: 5 (limit: 6005)
     Memory: 33.4M
        CPU: 183ms
     CGroup: /system.slice/etcd.service
             └─19808 /usr/bin/etcd

. . .
```

etcdctl user add root:123

etcdctl auth enable

etcdctl --user=root:123 user add etcd:%37C6s_YO19

etcdctl --user=etcd:%37C6s_YO19 --endpoints=http://192.168.56.111:2379 put x 7

etcdctl --user=root:123 --endpoints=http://192.168.56.111:2379 role add role_rw
etcdctl --user=root:123 --endpoints=http://192.168.56.111:2379 role grant-permission role_rw readwrite /
etcdctl --user=root:123 --endpoints=http://192.168.56.111:2379 user grant etcd role_rw

etcdctl --user=etcd:%37C6s_YO19 --endpoints=http://192.168.56.111:2379 put x 7