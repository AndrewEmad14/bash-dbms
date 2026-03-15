#!/usr/bin/env bash
set -euo pipefail

# list-tables.sh
# Provides: listTables <db_name>
# Lists tables in the specified database by reading metadata files.

if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi

listTables(){
  local DB_NAME="${1:-}"
  if [ -z "$DB_NAME" ]; then
    echo "listTables: missing database name" >&2
    return 0
  fi

  local dbDir="$DB_ROOT/$DB_NAME"
  if [ ! -d "$dbDir" ]; then
    echo "Database not found: $DB_NAME" >&2
    return 0
  fi

  shopt -s nullglob
  local metaFiles=("$dbDir"/*"$META_EXT")
  if [ "${#metaFiles[@]}" -eq 0 ]; then
    echo "No tables in database '$DB_NAME'."
    shopt -u nullglob
    return 0
  fi

  echo "Tables in database '$DB_NAME':"
  local f
  for f in "${metaFiles[@]}"; do
    # strip directory and extension
    local base
    base=$(basename "$f" "$META_EXT")
    echo "- $base"
  done
  shopt -u nullglob
}

export -f listTables
