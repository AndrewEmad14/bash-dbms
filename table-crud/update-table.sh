#!/usr/bin/env bash
set -euo pipefail

# Provides: updateFromTable <db_name>
# Supports: show all rows, or filter by a single column equality (WHERE col = value).
# Ensure config is loaded
if [ -z "${DB_ROOT:-}" ]; then
source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi
# Load helpers
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/dbValidations.sh"

updateTable(){
  local DB_NAME="${1:-}"
  if [ -z "$DB_NAME" ]; then
    echo "updateFromTable: missing database name" >&2
    return 0
  fi

  read -r -p "Enter table name to select from: " tableName
  tableName=$(trim "$tableName")

  local metaFile="$DB_ROOT/$DB_NAME/$tableName$META_EXT"
  local dataFile="$DB_ROOT/$DB_NAME/$tableName$DATA_EXT"

  if [ ! -f "$metaFile" ]; then
    echo "Table not found: $tableName" >&2
    return 0
  fi

  if ! validate_meta_file "$metaFile"; then
    echo "Invalid table metadata for $tableName" >&2
    return 0
  fi

  # parse metadata 
  local metaLine
  metaLine=$(sed -n '1p' "$metaFile" || echo "")
  IFS="$DELIM" read -r -a parts <<< "$metaLine"

  declare -a col_names
  declare -a col_types
  local pk_index=-1
  local i

  for i in "${!parts[@]}"; do
    IFS=':' read -r cname ctype cpk <<< "${parts[i]}"
    col_names[i]="$cname"
    col_types[i]="$ctype"
    if [[ "${parts[i]}" == *":PK" ]] || [[ "$cpk" == "PK" ]]; then
      pk_index=$i
    fi
  done

  # guard: no data 
  if [ ! -f "$dataFile" ] || [ ! -s "$dataFile" ]; then
    echo "(no rows)"
    return 0
  fi

  #  ask for PK value 
  local pkval
  while true; do
    read -r -p "Enter pk to filter by number: " pkval
    pkval=$(trim "$pkval")

    if [ -z "$pkval" ]; then
      echo "Please provide a pk value."
      continue
    fi

    if ! isPositiveInteger "$pkval"; then
      echo "Invalid pk: must be a positive integer."
      continue
    fi

    # check the PK actually exists in the data file
    local match
    match=$(awk -F"$DELIM" -v col="$pk_index" -v val="$pkval" \
      '$(col+1) == val { print NR; exit }' "$dataFile")

    if [ -z "$match" ]; then
      echo "No row found with pk = $pkval."
      continue
    fi

    break
  done

  #read the matched row into an array 
  local rowLine
  rowLine=$(awk -F"$DELIM" -v col="$pk_index" -v val="$pkval" \
    '$(col+1) == val { print; exit }' "$dataFile")

  IFS="$DELIM" read -r -a row_values <<< "$rowLine"

  #  prompt for new values (skip PK column)
  declare -a new_values
  for i in "${!col_names[@]}"; do
    new_values[i]="${row_values[i]}"          # default: keep existing

    if [ "$i" -eq "$pk_index" ]; then
      continue                                # always skip PK
    fi

    local current="${row_values[i]}"
    local newval

    read -r -p "  ${col_names[i]} (${col_types[i]}) [current: ${current}]: " newval
    newval=$(trim "$newval")

    if [ -z "$newval" ]; then
      echo "keeping existing value: ${current}"
      continue
    fi

    #  type validation 
    case "${col_types[i]}" in
      int|integer)
        if ! [[ "$newval" =~ ^-?[0-9]+$ ]]; then
          echo "  ✗ '${newval}' is not an integer — keeping existing value: ${current}"
          continue
        fi
        ;;
      float|number)
        if ! [[ "$newval" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
          echo "  ✗ '${newval}' is not a number — keeping existing value: ${current}"
          continue
        fi
        ;;
    esac

    new_values[i]="$newval"
  done

  # build the updated row string 
  local updated_row
  updated_row=$(IFS="$DELIM"; echo "${new_values[*]}")

  #replace matched line in-place 
  local tmpFile
  tmpFile=$(mktemp)

  awk -F"$DELIM" -v col="$pk_index" -v val="$pkval" -v newrow="$updated_row" \
    '$(col+1) == val { print newrow; next } { print }' \
    "$dataFile" > "$tmpFile"

  cat "$tmpFile" > "$dataFile"

  echo "Row with pk=${pkval} updated successfully."
  return 0
}