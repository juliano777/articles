# Instalção do Oracle Database

# https://docs.oracle.com/en/database/oracle/oracle-database/19/ladbi/running-rpm-packages-to-install-oracle-database.html#GUID-BB7C11E3-D385-4A2F-9EAF-75F4F0AACF02


dnf -y install oracle-database-preinstall-19c


# On Red Hat Enterprise Linux

curl -o oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm

yum -y localinstall oracle-database-preinstall-19c-1.0-1.el7.x86_64.rpm


dnf -y localinstall oracle-database-ee-19c-1.0-1.x86_64.rpm

/etc/init.d/oracledb_ORCLCDB-19c configure

# É preciso ter IP e hostname declarados no /etc/hosts

"
Database creation complete. For details check the logfiles at:
 /opt/oracle/cfgtoollogs/dbca/ORCLCDB.
Database Information:
Global Database Name:ORCLCDB
System Identifier(SID):ORCLCDB
Look at the log file "/opt/oracle/cfgtoollogs/dbca/ORCLCDB/ORCLCDB.log" for further details.

Database configuration completed successfully. The passwords were auto generated, you must change them by connecting to the database using 'sqlplus / as sysdba' as the oracle user.
"

cat << EOF > ~oracle/.oravars && chown oracle: ~oracle/.oravars
export ORACLE_VERSION='19c'
export ORACLE_HOME="/opt/oracle/product/\${ORACLE_VERSION}/dbhome_1"
export ORACLE_SID='ORCLCDB'
export PATH="\${PATH}:\${ORACLE_HOME}/bin"
EOF

# Como usuário oracle:
sqlplus / as sysdba

SELECT 1 AS coluna FROM DUAL;

https://www.oracle.com/br/database/technologies/appdev/sqldeveloper-landing.html


https://docs.oracle.com/en/database/oracle/oracle-database/19/comsc/database-sample-schemas.pdf


cd $ORACLE_HOME/demo/schema/human_resources

sqlplus / as sysdba

@?/demo/schema/human_resources/hr_main.sql


3. Enter a secure password for HR
specify password for HR as parameter 1:
Enter value for 1:
Enter an appropriate tablespace, for example, users as the default tablespace for
HR
specify default tablespace for HR as parameter 2:
Enter value for 2:
4. Enter temp as the temporary tablespace for HR
specify temporary tablespace for HR as parameter 3:
Enter value for 3:
5. Enter your SYS password
specify password for SYS as parameter 4:
Enter value for 4:
6. Enter the directory path, for example, $ORACLE_HOME/demo/schema/log/, for your
log directory
specify log path as parameter 5:
Enter value for 5:
After script hr_main.sql runs successfully and schema HR is installed, you are
connected as user HR. To verify that the schema was created, use the following
command:
SQL> SELECT table_name FROM user_tables;



select username as schema_name
from sys.all_users
order by username;


# PostgreSQL

https://www.oracle.com/br/database/technologies/instant-client/linux-x86-64-downloads.html


read -p 'Cole a URL do RPM: ' URL


dnf install -y \
perl perl-ExtUtils-MakeMaker perl-DBI wget gcc perl-DBD-Pg \
https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-basic-21.6.0.0.0-1.el8.x86_64.rpm \
https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-sqlplus-21.6.0.0.0-1.el8.x86_64.rpm \
https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-devel-21.6.0.0.0-1.el8.x86_64.rpm \
https://download.oracle.com/otn_software/linux/instantclient/216000/oracle-instantclient-jdbc-21.6.0.0.0-1.el8.x86_64.rpm

https://blog.dbi-services.com/migrating-from-oracle-to-postgresql-with-ora2pg/


export PATH="${PATH}:/usr/pgsql-14/bin"

perl -MCPAN -e 'install DBD::Oracle'
perl -MCPAN -e 'install DBD::MySQL'
perl -MCPAN -e 'install Time::HiRes'
perl -MCPAN -e 'install DBD::Pg'
perl -MCPAN -e 'install Compress::Zlib'

cd ~/.cpan/build/DBD-Oracle-1.83-0/

make && make install



cat << EOF > /etc/profile.d/oracle
export ORACLE_CLIENT_VERSION='21'
export ORACLE_HOME="/usr/lib/oracle/${ORACLE_CLIENT_VERSION}/client64"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${ORACLE_HOME}/lib"
export PATH="${PATH}:${ORACLE_HOME}/bin"
EOF


cd /tmp

wget https://github.com/darold/ora2pg/archive/refs/tags/v23.1.tar.gz

tar xvf v23.1.tar.gz

cd ora2pg-23.1/

perl Makefile.PL

make && make install

echo -e '\nsource /etc/profile.d/oracle' >> ~postgres/.bash_profile

chown -R postgres: /etc/ora2pg

su - postgres

cp /etc/ora2pg/ora2pg.conf.dist /etc/ora2pg/ora2pg.conf

vim /etc/ora2pg/ora2pg.conf

createdb db_hr

ora2pg --project_base . --init_project hr

cd hr

cat << EOF > config/ora2pg.conf
ORACLE_HOME     /usr/lib/oracle/21/client64
ORACLE_DSN      dbi:Oracle:host=192.168.56.100;sid=ORCLCDB;port=1521
ORACLE_USER     system
ORACLE_PWD      123
SCHEMA          hr
PG_VERSION      14
PG_SUPPORTS_PROCEDURE   1
KEEP_PKEY_NAMES         0
DROP_FKEY 1
EOF


./export_schema.sh

mkdir -p /var/lib/pgsql/14/ts/alpha

cat schema/tablespaces/tablespace.sql

sed -i 's:/opt/oracle/oradata/ORCLCDB/users01.dbf/USERS:/var/lib/pgsql/14/ts/alpha:g' schema/tablespaces/tablespace.sql

sed -i 's:users:ts_alpha:g' schema/tablespaces/tablespace.sql

sed -i '/ALTER INDEX/d' schema/tablespaces/tablespace.sql

echo 'ALTER INDEX ALL IN TABLESPACE pg_default SET TABLESPACE ts_alpha;' >> schema/tablespaces/tablespace.sql

cat schema/tablespaces/tablespace.sql

./import_all.sh -o postgres -d db_hr -U postgres -h localhost -y

psql db_hr
