#!/bin/sh

### BEGIN INIT INFO
# Provides:             postgresql
# Required-Start:       $local_fs $remote_fs $network $time
# Required-Stop:        $local_fs $remote_fs $network $time
# Short-Description:    PostgreSQL RDBMS
# Default-Start:        2 3 4 5
# Default-Stop:         
### END INIT INFO

export PGVERSION=
export PGDATA="/var/lib/pgsql/${PGVERSION}/main"	# Data directory
export PGCONF="/etc/pgsql/${PGVERSION}/main"	# Configuration directory
export PGDATABASE='postgres'	# Database for connection
export PGUSER='postgres'	# Database user
export PGBIN="/usr/local/pgsql/${PGVERSION}/bin"

## ==================================================================

## UNIX SOCKET DIRECTORY ##

if [ ! -d /var/run/postgresql ]; then 
    mkdir /var/run/postgresql
fi

chown -R ${PGUSER}: /var/run/postgresql

## ==================================================================

## FUNCTIONS ##

func_dir_is_empty(){
    # Function that returns true if the directory is empty
    
    DIRCOUNT=`ls -A ${1} 2> /dev/null | wc -l`
    if [ ! -x ${1} -o ${DIRCOUNT} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

func_dir_has_no_files(){
    # Function that returns true if the directory has no files 

    NUMFILES=`ls -lA ${1} 2> /dev/null | egrep '^-.{9}' | \
    awk '{print $(NF)}' | wc -l`
    if [ ${NUMFILES} -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

func_start(){
    # Function to start the PostgreSQL service

    echo "Starting the PostgreSQL Database Service"
    su ${PGUSER} -c "${PGBIN}/pg_ctl -D ${PGDATA} start" &> /dev/null
}

func_stop(){
    # Function to stop the PostgreSQL service

    echo "Stopping PostgreSQL"
    su ${PGUSER} -c "${PGBIN}/pg_ctl stop -D ${PGDATA} -m fast" &> /dev/null
}

func_restart(){
    # Function to restart the PostgreSQL service

    func_stop
    func_start
}

func_reload(){
    # Function to reload the PostgreSQL without restart the service

    echo "Reloading PostgreSQL configurations"
    su ${PGUSER} -c "${PGBIN}/pg_ctl  -D ${PGDATA} reload" &> /dev/null
}

func_initdb(){
    # Function to create the main cluster of PostgreSQL

    if (! func_dir_is_empty ${PGDATA}); then
        echo "The PGDATA directory (${PGDATA}) is not empty!"
        exit 1
    fi

    if (! func_dir_has_no_files ${PGCONF}); then
        DIRBKPID=`date +%Y%m%d%H%M`
        mkdir -p ${PGCONF}/bkp/${DIRBKPID}
        ls -l ${PGCONF}/* | egrep '^-.{9}' | awk '{print $(NF)}' | \
        xargs -i mv {} ${PGCONF}/bkp/${DIRBKPID}/
    fi

    echo "Creating PostgreSQL cluster";
    su - ${PGUSER} -c "${PGBIN}/initdb -E utf8 -D ${PGDATA}" &> /dev/null
    mv ${PGDATA}/*.conf ${PGCONF}/
    ls -l ${PGCONF}/* | egrep '^-.{9}' | awk '{print $(NF)}' | \
    xargs -i ln -s {} ${PGDATA}/
}

## ==================================================================

## EVALUATION OF PARAMETERS ## 

case ${1} in
    'start')
        func_start
        ;;

    'stop')
        func_stop
        ;;

    'restart')
        func_restart
        ;;

    'reload')
        func_reload
        ;;

    'status')
        su ${PGUSER} -c "${PGBIN}/pg_ctl -D ${PGDATA} status" 2> /dev/null
        ;;

    'initdb')
        func_initdb
        ;;

    *)
        echo "Use ${0} (start | stop | restart | reload | status | initdb )"
        ;;
esac

## ==================================================================
