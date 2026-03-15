#!/bin/bash
set -euo pipefail

if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/dbValidations.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../table-crud/tableMain.sh"

connectToDatabase(){
  read -p "Please enter your db name you wish to connect to: " dbName
  if ! isDBExists "$dbName" ; then
    echo "database doesn't exist"
  else
    echo "connected to $dbName database"
    runTableCRUD "$dbName"
  fi
}
