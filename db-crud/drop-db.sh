#!/bin/bash
set -euo pipefail

if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/dbValidations.sh"

dropDatabase(){
  read -p "Please enter your db name you wish to drop: " dbName
  if ! isDBExists "$dbName" ; then
    echo "database doesn't exist"
  else
    rm -rf "$DB_ROOT/$dbName"
    echo "database dropped"
  fi
}
