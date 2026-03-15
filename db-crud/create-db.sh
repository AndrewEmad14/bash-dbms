#!/bin/bash
set -euo pipefail

# Ensure config is loaded
if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/dbValidations.sh"

createDatabase(){
  read -p "Please enter your db name (lowercase letters, numbers, underscores): " dbName
  if isDBExists "$dbName" ; then
    echo "database already exists"
  elif ! validateName "$dbName" ; then
    echo "invalid format, please try again"
  else
    mkdir -p "$DB_ROOT/$dbName"
    echo "database created successfully"
  fi
}
