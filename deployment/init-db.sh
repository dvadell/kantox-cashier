#!/bin/bash
set -ex

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER"  <<-EOSQL
	CREATE USER cashier WITH PASSWORD '${DB_PASSWORD}';
	GRANT ALL PRIVILEGES ON DATABASE cashier_prod TO cashier;
	ALTER DATABASE cashier_prod OWNER TO cashier;
EOSQL
