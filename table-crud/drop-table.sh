#!/usr/bin/env bash
set -euo pipefail


# Ensure config is loaded
if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi

# Load validation helpers
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/dbValidations.sh"


dropTable(){
  read -p "Please enter your table name you wish to drop: " tableName
  if ! isTableExists "$DB_NAME" "$tableName" ; then
    echo "table doesn't exist"
  else
    rm -rf "$DB_ROOT/$DB_NAME/$tableName.data" "$DB_ROOT/$DB_NAME/$tableName.meta" "$DB_ROOT/$DB_NAME/${tableName}.idx" 
    echo "table dropped $DB_ROOT/$DB_NAME/$tableName"
  fi
}