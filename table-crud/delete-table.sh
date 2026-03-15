#!/usr/bin/env bash
set -euo pipefail

# select-from-table.sh
# Provides: selectFromTable <db_name>
# Interactive selection / viewing of table rows.
# Supports: show all rows, or filter by a single column equality (WHERE col = value).

# Ensure config is loaded
if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi

# Load helpers
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/dbValidations.sh"

deleteFromTable(){
  local DB_NAME="${1:-}"
  if [ -z "$DB_NAME" ]; then
    echo "deleteFromTable: missing database name" >&2
    return 0
  fi

  read -r -p "Enter table name to delete from: " tableName
  tableName=$(trim "$tableName")
  local metaFile="$DB_ROOT/$DB_NAME/$tableName$META_EXT"
  local dataFile="$DB_ROOT/$DB_NAME/$tableName$DATA_EXT"
  local indexFile="$DB_ROOT/$DB_NAME/${tableName}$IDX_EXT"
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

  # Ask user whether to filter
  local choice
  while true; do
    echo "\n delete options:"
    echo "1) delete all rows"
    echo "2) Filter rows (WHERE column = value)"
    read -r -p "Choose 1 or 2: " choice
    case "$choice" in
      1|2) break ;;
      *) echo "Please enter 1 or 2." ;;
    esac
  done

  # if data file missing or empty, nothing to show
  if [ ! -f "$dataFile" ] || [ ! -s "$dataFile" ]; then
    echo "(no rows)"
    return 0
  fi

  local matched=0
  # delete all rows , just truncate data and index files
  if [ "$choice" -eq 1 ]; then
    # delete all: just truncate data file
    matched=$(wc -l < "$dataFile")
    echo "" > "$dataFile"
    echo "" > "$indexFile"
    echo "-- $matched row(s) deleted --"
    return 0
  fi

  # choice == 2: delete by filter

  # ask which column to filter by
  local filter_col
  local filter_idx=-1
  while true; do
    read -r -p "Enter column to filter by (name or number): " filter_col
    filter_col=$(trim "$filter_col")
    if [ -z "$filter_col" ]; then
      echo "Please provide a column name or number.";
      continue
    fi
    if [[ "$filter_col" =~ ^[0-9]+$ ]]; then
      if isPositiveInteger "$filter_col" && [ "$filter_col" -le "${#col_names[@]}" ]; then
        filter_idx=$((filter_col-1)); break
      else
        echo "Invalid column number."; continue
      fi
    fi
    # match by name
    local found=0
    for i in "${!col_names[@]}"; do
      if [ "${col_names[i]}" = "$filter_col" ]; then
        filter_idx=$i; found=1; break
      fi
    done
    if [ "$found" -eq 1 ]; then break; fi
    echo "No column named '$filter_col' found.";
  done

  # get filter value and validate type
  local filter_val
  while true; do
    read -r -p "Enter value to match for column '${col_names[filter_idx]}' (type=${col_types[filter_idx]}): " filter_val
    filter_val=$(trim "$filter_val")
    if [ -z "$filter_val" ]; then
      echo "Filter value cannot be empty."; continue
    fi
    if ! validateValueByType "$filter_val" "${col_types[filter_idx]}"; then
      echo "Value does not match type '${col_types[filter_idx]}'."; continue
    fi
    break
  done

  local tempDataFile="$(mktemp)"
  local tempIdxFile="$(mktemp)"
  local index=1
  # scan and print matching rows
  while IFS= read -r line || [ -n "$line" ]; do
    IFS="$DELIM" read -r -a fields <<< "$line"
    local val="${fields[filter_idx]:-}"
    if [ "$val" != "$filter_val" ]; then
      echo $((index)) >> "$tempIdxFile"
      # print row
      local out=""
      local j
      for j in "${!col_names[@]}"; do
        local v="${fields[j]:-}"
        if [ -z "$out" ]; then out="$v"; else out+="$DELIM$v"; fi
      done
      echo "$out" >> "$tempDataFile"  
      matched=$((matched+1))
    fi
    index=$((index+1))
  done < "$dataFile"
  cat "$tempDataFile" > "$dataFile"
  cat "$tempIdxFile" > "$indexFile"
  rm "$tempDataFile" "$tempIdxFile"
  echo "-- $matched row(s) deleted --"
  return 0
}

export -f deleteFromTable
