#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" <<-EOSQL
    create table mytable (c1 integer);
EOSQL