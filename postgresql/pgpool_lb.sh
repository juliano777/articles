./configure --prefix='/usr/local/pgpool' --bindir='/usr/local/bin' --sbindir='/usr/local/sbin' --with-pgsql='/usr/pgsql-10'

make

make install

cd src/sql

make

make install

psql -c 'CREATE EXTENSION pgpool_recovery;' db_repmgr




SELECT inet_server_addr();



createdb -O rep_radar_pro db_pgpool

psql -c 'CREATE SCHEMA sc_pgpool AUTHORIZATION rep_radar_pro' db_pgpool


psql -c 'CREATE SCHEMA sc_pgpool AUTHORIZATION rep_radar_pro' db_pgpool


cat << EOF | psql -U rep_radar_pro db_pgpool
CREATE TABLE sc_pgpool.dist_def (
    dbname text, -- database name
    schema_name text, -- schema name
    table_name text, -- table name
    col_name text NOT NULL CHECK (col_name = ANY (col_list)), -- distribution key-column
    col_list text[] NOT NULL, -- list of column names
    type_list text[] NOT NULL, -- list of column types
    dist_def_func text NOT NULL, -- distribution function name
    PRIMARY KEY (dbname, schema_name, table_name)
);
EOF






psql -c 'CREATE EXTENSION dblink AUTHORIZATION rep_radar_pro' db_pgpool
