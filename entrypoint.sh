#!/usr/bin/env bash
#set -Eeo pipefail

echo Postgresql login is $POSTGRES_USER with password $POSTGRES_PASSWORD
echo Java home is: $JAVA_HOME

pg_start() {
    if [ ! -f /var/lib/postgresql/12/main/PG_VERSION ] ; then
        is_first_start=true
	fi

    /etc/init.d/postgresql start
    echo postgresql started!

    if $is_first_start ; then
        
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

main() {
    gosu postgres "$BASH_SOURCE" pg_start

    jpc_start

    tail -f /var/log/jchem-psql/info.log
}


if [ "$1" = 'pg_start' ] ; then
    pg_start
elif [ "$1" = 'jpc_pg_init' ] ; then
    jpc_pg_init
else    
    main   
fi
