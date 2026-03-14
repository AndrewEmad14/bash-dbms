#!/usr/bin/env bash
set -euo pipefail

# create-table.sh
# Provides: createTable <db_name>
# Interactive creation of a table inside a connected database.
#
# New behavior: user first enters all column names and types. After that,
# the script prompts the user to pick which column will be the primary key
# (by number or by name), or leave empty for no primary key. This reduces
# mistakes and lets the user choose the PK after seeing the full schema.

# Ensure config is loaded (DB_ROOT, DELIM, META_EXT, DATA_EXT, IDX_EXT)
if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi

# Load validation helpers
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/dbValidations.sh"

createTable(){
  local DB_NAME="${1:-}"
  if [ -z "$DB_NAME" ]; then
    echo "createTable: missing database name" >&2
    return 1
  fi

  # Table name
  local tableName
  read -r -p "Enter table name: " tableName
  tableName=$(trim "$tableName")
  if ! validateName "$tableName" ; then
    echo "Invalid table name. Must start with a lowercase letter and contain only lowercase letters, digits or underscore." >&2
    return 1
  fi

  local tableMetaFile="$DB_ROOT/$DB_NAME/$tableName$META_EXT"
  if [ -e "$tableMetaFile" ]; then
    echo "Table already exists: $tableName" >&2
    return 1
  fi

  # Number of columns
  local colCount
  while true; do
    read -r -p "Enter number of columns: " colCount
    colCount=$(trim "$colCount")
    if isPositiveInteger "$colCount"; then
      break
    fi
    echo "Please enter a positive integer for number of columns."
  done

  # Collect column definitions
  declare -a col_names
  declare -a col_types
  local i
  for i in $(seq 1 "$colCount"); do
    # Column name
    local colName
    while true; do
      read -r -p "Column $i name: " colName
      colName=$(trim "$colName")
      if ! validateName "$colName" ; then
        echo "Invalid column name. Must start with a lowercase letter and contain only lowercase letters, digits or underscore."
        continue
      fi
      # ensure uniqueness
      local found=0
      local j
      for j in "${!col_names[@]}"; do
        if [ "${col_names[j]}" = "$colName" ]; then
          found=1
          break
        fi
      done
      if [ "$found" -eq 1 ]; then
        echo "Column name '$colName' already used. Choose a different name."
        continue
      fi
      break
    done

    # Column type
    local colType
    while true; do
      read -r -p "Column $i type (int|string|float|date): " colType
      colType=$(trim "$colType")
      case "$colType" in
        int|string|float|date)
          break
          ;;
        *)
          echo "Invalid type. Allowed: int string float date"
          ;;
      esac
    done

    col_names[$((i-1))]="$colName"
    col_types[$((i-1))]="$colType"
  done

  # Let the user choose the primary key after seeing all columns.
  local pk_index=-1
  while true; do
    echo "\nColumns defined:"
    for i in "${!col_names[@]}"; do
      echo "$((i+1))). ${col_names[i]} (${col_types[i]})"
    done
    read -r -p "Enter primary key column (number or name) (required): " pkChoice
    pkChoice=$(trim "$pkChoice")
    if [ -z "$pkChoice" ]; then
      echo "A primary key is required. Please choose a column number or name."
      continue
    fi
    # if integer index provided
    if [[ "$pkChoice" =~ ^[0-9]+$ ]]; then
      if isPositiveInteger "$pkChoice" && [ "$pkChoice" -le "${#col_names[@]}" ]; then
        pk_index=$((pkChoice-1))
        break
      else
        echo "Invalid column number. Please choose a valid number from the list."
        continue
      fi
    fi
    # otherwise try to match by name
    local found=0
    for i in "${!col_names[@]}"; do
      if [ "${col_names[i]}" = "$pkChoice" ]; then
        pk_index=$i
        found=1
        break
      fi
    done
    if [ "$found" -eq 1 ]; then
      break
    fi
    echo "No column named '$pkChoice' found. Please provide a valid column name or number."
  done

  # Build metadata line
  local metaLine=""
  for i in "${!col_names[@]}"; do
    local entry="${col_names[i]}:${col_types[i]}"
    if [ "$i" -eq "$pk_index" ]; then
      entry+=":PK"
    fi
    if [ -n "$metaLine" ]; then
      metaLine+="$DELIM"
    fi
    metaLine+="$entry"
  done

  # Show summary and confirm
  printf "\nTable: %s\n" "$tableName"
  echo "Schema: $metaLine"
  if ! prompt_confirm "Create table with the above schema? (y/N): " n; then
    if prompt_confirm "Restart table creation? (y/N): " n; then
      createTable "$DB_NAME"
      return $?
    fi
    echo "Aborting table creation." >&2
    return 1
  fi

  # Ensure DB directory exists and write files
  mkdir -p "$DB_ROOT/$DB_NAME"
  echo "$metaLine" > "$tableMetaFile"
  : > "$DB_ROOT/$DB_NAME/$tableName$DATA_EXT"
  : > "$DB_ROOT/$DB_NAME/$tableName$IDX_EXT"

  echo "Table '$tableName' created successfully in database '$DB_NAME'."
}

export -f createTable
