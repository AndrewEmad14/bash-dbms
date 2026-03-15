#!/usr/bin/env bash
set -euo pipefail

# insert-into-table.sh
# Provides: insertIntoTable <db_name>
# Interactive insertion of a row into a table. Primary key is entered by the user
# (no auto-increment). The user may choose to defer entering the PK when
# prompted for column values; the script will require and validate the PK
# before saving the row. This avoids forcing the PK to be entered first while
# ensuring uniqueness and correct type.

# Ensure config is loaded
if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi

# Load validation helpers
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/dbValidations.sh"

insertIntoTable(){
  # :-  default to empty string if not provided , it isnt required but is there for readability
  local DB_NAME="${1:-}"
  if [ -z "$DB_NAME" ]; then
    echo "insertIntoTable: missing database name" >&2
    return 0
  fi

  read -r -p "Enter table name to insert into: " tableName
  tableName=$(trim "$tableName")
  local metaFile="$DB_ROOT/$DB_NAME/$tableName$META_EXT"
  local dataFile="$DB_ROOT/$DB_NAME/$tableName$DATA_EXT"
  local idxFile="$DB_ROOT/$DB_NAME/$tableName$IDX_EXT"

  if [ ! -f "$metaFile" ]; then
    echo "Table not found: $tableName" >&2
    return 0
  fi

  # validate meta file
  if ! validate_meta_file "$metaFile"; then
    echo "Invalid table metadata for $tableName" >&2
    return 0
  fi

  # read metadata header (first line)
  local metaLine
  metaLine=$(sed -n '1p' "$metaFile" || echo "")
  if [ -z "$metaLine" ]; then
    echo "Invalid or empty metadata for table $tableName" >&2
    return 0
  fi

  # parse columns
  IFS="$DELIM" read -r -a parts <<< "$metaLine"
  declare -a col_names
  declare -a col_types
  local pk_index=-1

  local i
  for i in "${!parts[@]}"; do
    # each part: name:type[:PK]
    IFS=':' read -r cname ctype cpk <<< "${parts[i]}"
    col_names[i]="$cname"
    col_types[i]="$ctype"
    if [[ "${parts[i]}" == *":PK" ]] || [[ "$cpk" == "PK" ]]; then
      pk_index=$i
    fi
  done

  # ensure idx file exists
  ensureIndexFile "$DB_NAME" "$tableName"

  # collect values. User may defer entering PK; we will require/validate it later
  declare -a values
  for i in "${!col_names[@]}"; do
    local colName="${col_names[i]}"
    local colType="${col_types[i]}"
    local val

    while true; do
      if [ "$i" -eq "$pk_index" ]; then
        read -r -p "Enter value for PRIMARY KEY '${colName}' (type=${colType}) [press enter to defer]: " val
      else
        read -r -p "Enter value for '${colName}' (type=${colType}) [press enter to leave empty]: " val
      fi
      val=$(trim "$val")

      # If user deferred (empty) for non-PK, accept empty. For PK, accept empty now but require later.
      if [ -z "$val" ]; then
        values[i]=""
        break
      fi

      # disallow delimiter inside values
      if ! validateNoDelimiter "$val" ; then
        echo "Value may not contain the field delimiter '$DELIM'. Please remove it." >&2
        continue
      fi

      # Validate type immediately for any provided value
      if ! validateValueByType "$val" "$colType" ; then
        echo "Value does not match type '$colType'. Please try again." >&2
        continue
      fi

      values[i]="$val"
      break
    done
  done

  # Ensure primary key is provided and unique before saving
  if [ "$pk_index" -ge 0 ]; then
    while true; do
      local pkval="${values[$pk_index]}"
      if [ -z "$pkval" ]; then
        read -r -p "Primary key '${col_names[$pk_index]}' is required. Enter value: " pkval
        pkval=$(trim "$pkval")
      fi

      if [ -z "$pkval" ]; then
        echo "Primary key cannot be empty. Please enter a value." >&2
        continue
      fi
      if ! validateNoDelimiter "$pkval" ; then
        echo "Primary key may not contain the field delimiter '$DELIM'. Please remove it." >&2
        values[$pk_index]=""
        continue
      fi

      if ! validateValueByType "$pkval" "${col_types[$pk_index]}" ; then
        echo "Value does not match type '${col_types[$pk_index]}'. Please try again." >&2
        # reset so user can re-enter
        values[$pk_index]=""
        continue
      fi

      if ! isPrimaryKey "$DB_NAME" "$tableName" "$pkval" ; then
        echo "Primary key value '$pkval' already exists. Enter a different value." >&2
        # reset and reprompt
        values[$pk_index]=""
        continue
      fi

      values[$pk_index]="$pkval"
      break
    done
  fi

  # join values with delimiter
  local record
  record=""
  for i in "${!values[@]}"; do
    if [ "$i" -eq 0 ]; then
      record="${values[$i]}"
    else
      record+="$DELIM${values[$i]}"
    fi
  done

  # append to data file and update idx if PK exists
  echo "$record" >> "$dataFile"
  if [ "$pk_index" -ge 0 ]; then
    echo "${values[$pk_index]}" >> "$idxFile"
  fi
  echo "Row inserted into $tableName"
}

export -f insertIntoTable
