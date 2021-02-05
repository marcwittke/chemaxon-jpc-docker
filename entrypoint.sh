#!/usr/bin/env bash
#set -Eeo pipefail

pg_start() {
    echo starting postgresql...!
    /etc/init.d/postgresql start
    echo postgresql started!

    role_count=`psql -At -c "SELECT count(*) FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_USER'"`

    if [ 0 -eq ${role_count:-0} ] ; then
        
        echo Creating role $POSTGRES_USER
        psql -c "CREATE role $POSTGRES_USER WITH LOGIN SUPERUSER ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';"
        
        echo Creating $POSTGRES_USER\'s database
        createdb -O $POSTGRES_USER $POSTGRES_USER

        echo first start done!
    fi
}

jpc_pg_init() {
    psql -d $POSTGRES_USER --command "CREATE EXTENSION IF NOT EXISTS chemaxon_type;"
    psql -d $POSTGRES_USER --command "CREATE EXTENSION IF NOT EXISTS hstore;"
    psql -d $POSTGRES_USER --command "CREATE EXTENSION IF NOT EXISTS chemaxon_framework;"
}


jpc_start() {
    echo initializing JPC...
    /etc/init.d/jchem-psql init
    

    echo starting JPC...
    /etc/init.d/jchem-psql start

    gosu postgres "$BASH_SOURCE" jpc_pg_init
}

shutdown() {
  echo "shutting down..."
  
  /etc/init.d/jchem-psql stop
  /etc/init.d/postgresql stop

  echo done!
}

main() {

    echo Postgresql login is $POSTGRES_USER with password $POSTGRES_PASSWORD
    echo Java home is: $JAVA_HOME


    gosu postgres "$BASH_SOURCE" pg_start

    jpc_start
    
    trap shutdown EXIT
    
    tail -f /var/log/jchem-psql/info.log
}


if [ "$1" = 'pg_start' ] ; then
    pg_start
elif [ "$1" = 'jpc_pg_init' ] ; then
    jpc_pg_init
else    
    main   
fi
