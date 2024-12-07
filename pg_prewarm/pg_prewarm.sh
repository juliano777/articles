mkdir -m 0700 /prewarm

chown postgres: /prewarm

vim ${PGDATA}/postgresql.conf

"
pg_prewarm.autoprewarm = on
pg_prewarm.autoprewarm_interval = 300s
"

cat << EOF >> /etc/sysctl.d/pgsql.conf
vm.overcommit_memory = 2
vm.overcommit_ratio = 90
vm.nr_hugepages = 2132
vm.hugetlb_shm_group = 98
EOF


cat << EOF > /etc/security/limits.d/pgsql.conf
postgres    hard   memlock 4367170
postgres    soft   memlock 4367170
EOF


