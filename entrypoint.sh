#!/usr/bin/env bash
set -Eeo pipefail

pg_start() {
    echo "===> starting postgresql..."
    /etc/init.d/postgresql start
    echo "postgresql started"

    role_count=`psql -At -c "SELECT count(*) FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_USER'"`

    if [ 0 -eq ${role_count:-0} ] ; then
        
        echo "First start detected. creating role and respective database..."
        echo "Creating role $POSTGRES_USER"
        psql -c "CREATE role $POSTGRES_USER WITH LOGIN SUPERUSER ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';"
        
        echo "Creating $POSTGRES_USER\'s database"
        createdb -O $POSTGRES_USER $POSTGRES_USER

        echo "First start done"
    fi
}

jpc_init() {
    echo "===> Initializing JChem Postgres Cartridge..."
    
    LOG_FILE=/var/log/jchem-psql/stdout.log
    ERROR_LOG=/var/log/jchem-psql/stderr.log
    export JCHEM_PSQL_OPTS=" -Dlog4j.configurationFile=/etc/chemaxon/jpc-log4j.xml --add-opens=java.base/java.nio=ALL-UNNAMED"   

    /opt/jchem-psql/bin/jchem-psql -I -c /etc/chemaxon/jchem-psql.conf
    echo "JChem Postgres Cartridge initialized"
}

jpc_init_pg() {
    echo "===> Creating extensions..."
    psql -d $POSTGRES_USER --command "CREATE EXTENSION IF NOT EXISTS chemaxon_type;"
    psql -d $POSTGRES_USER --command "CREATE EXTENSION IF NOT EXISTS hstore;"
    psql -d $POSTGRES_USER --command "CREATE EXTENSION IF NOT EXISTS chemaxon_framework;"
    echo "Extensions created."
}

shutdown() {
  echo "===> Shutting down..."
  
  /etc/init.d/postgresql stop

  echo "done."
}

main() {

    echo "Postgresql login is $POSTGRES_USER with password $POSTGRES_PASSWORD"
    echo "Java home is: $JAVA_HOME"

    trap shutdown EXIT

    # restart as user postgres and exec function pg_start (start postgres and ensure user with own db)
    gosu postgres "$BASH_SOURCE" pg_start

    # restart as user jchem_psql and exec function jpc_init (initialize cartridge against postgres)
    gosu jchem-psql "$BASH_SOURCE" jpc_init

    # restart as user postgres and exec function jpc_init_pg (create pg extensions)
    gosu postgres "$BASH_SOURCE" jpc_init_pg

    echo "===> Starting JChem Postgres Cartridge..."
    gosu jchem-psql /opt/jchem-psql/bin/jchem-psql -c /etc/chemaxon/jchem-psql.conf
}


if [ "$1" = 'pg_start' ] ; then
    pg_start
elif [ "$1" = 'jpc_init' ] ; then
    jpc_init
elif [ "$1" = 'jpc_init_pg' ] ; then
    jpc_init_pg
else    
    main   
fi
