#!/bin/bash
set -xe

PG_LOG=/var/log/postgresql/
PG_CONFIG_DIR=/etc/pgbouncer
PG_USER=postgres

if [ -f ${PG_CONFIG_DIR}/pgbouncer.ini ]; then
    rm ${PG_CONFIG_DIR}/pgbouncer.ini
else
    mkdir -p ${PG_CONFIG_DIR}
fi

cp /mnt/private.pem ${PG_CONFIG_DIR}/private.pem
chmod 400 /private.pem ${PG_CONFIG_DIR}/private.pem
cp /mnt/public.pem ${PG_CONFIG_DIR}/public.pem
chmod 400 /public.pem ${PG_CONFIG_DIR}/public.pem

echo "create pgbouncer config in ${PG_CONFIG_DIR}"

printf "\
[databases]
${DB_NAME} = host=${DB_HOST:?"Setup pgbouncer config error! You must set DB_HOST env"} port=${DB_PORT:-5432} \
${DB_PASSWORD:+password=${DB_PASSWORD}}

[pgbouncer]
logfile = /var/log/postgresql/pgbouncer.log
pidfile = /var/run/postgresql/pgbouncer.pid

listen_addr = 0.0.0.0
listen_port = 5432

unix_socket_dir = /var/run/postgresql

auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt

pool_mode = transaction

server_reset_query = DISCARD ALL

max_client_conn = 5000
default_pool_size = 180

admin_users = ${PGBOUNCER_ADMIN_USERS}

client_tls_sslmode = require
client_tls_key_file = /etc/pgbouncer/private.pem
client_tls_cert_file = /etc/pgbouncer/public.pem
client_tls_ca_file = /etc/pgbouncer/public.pem
client_tls_protocols = secure

# fivetran connects with extra_float_digits.
# See ref for extra_float_digits:
# https://www.postgresql.org/docs/9.6/static/runtime-config-client.html
#
# DEVOPS-1640
ignore_startup_parameters = extra_float_digits
" > ${PG_CONFIG_DIR}/pgbouncer.ini

IFS=',' read -r -a pg_usernames <<< "$PG_USERS"
IFS=',' read -r -a pg_passwords <<< "$PG_PASSWORDS"

for index in "${!pg_usernames[@]}"
do
    printf "\"${pg_usernames[index]}\" \"${pg_passwords[index]}\"" >> ${PG_CONFIG_DIR}/userlist.txt
done

mkdir -p ${PG_LOG}
chmod -R 755 ${PG_LOG}
chown -R ${PG_USER}:${PG_USER} ${PG_LOG}

echo "Starting pgbouncer..."
ls -al /etc/pgbouncer
cat ${PG_CONFIG_DIR}/pgbouncer.ini
cat ${PG_CONFIG_DIR}/userlist.txt
pgbouncer -u $PG_USER ${PG_CONFIG_DIR}/pgbouncer.ini
