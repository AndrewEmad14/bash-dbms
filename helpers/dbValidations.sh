#!/usr/bin/env bash
set -euo pipefail

# dbValidations.sh
# Collection of validation and helper functions used across the bash-dbms project.
# Functions include name validation, type validation, existence checks, trimming
# and simple prompts. Designed to be robust and reusable.

# Load config if not already loaded
if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi

# Validate identifier names (database, table, column)
# Must start with a lowercase letter and may contain lowercase letters, digits, underscore
validateName(){
  [[ "$1" =~ ^[a-z][a-z0-9_]*$ ]]
}

# Backwards-compatible alias used in other scripts: checks for database directory
isExsist(){
  [ -d "$DB_ROOT/$1" ]
}

# Explicit DB exists check
isDBExists(){
  [ -d "$DB_ROOT/$1" ]
}

# Table exists? (checks for metadata file)
isTableExists(){
  local db="$1"; local table="$2"
  [ -f "$DB_ROOT/$db/$table$META_EXT" ]
}

# Trim leading/trailing whitespace
trim(){
  local var="$*"
  # remove leading whitespace
  var="${var#${var%%[![:space:]]*}}"
  # remove trailing whitespace
  var="${var%${var##*[![:space:]]}}"
  printf '%s' "$var"
}

# Validate positive integer (used for column count)
isPositiveInteger(){
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# Integer check
isInteger(){
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

# Float check
isFloat(){
  [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

# Date check (YYYY-MM-DD). Uses regex and -- if available -- `date -d` to verify real date.
isDate(){
  local d="$1"
  # basic YYYY-MM-DD pattern and month/day ranges
  if ! [[ "$d" =~ ^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$ ]]; then
    return 1
  fi
  # if `date` is available, try to parse and ensure normalization matches
  if command -v date >/dev/null 2>&1; then
    local parsed
    parsed=$(date -d "$d" +%F 2>/dev/null) || return 1
    [ "$parsed" = "$d" ]
  else
    # fall back to regex-only check
    return 0
  fi
}

# Generic value validation according to a type name
# Supported types: int, float, date, string
validateValueByType(){
  local val="$1"
  local typ="$2"
  case "$typ" in
    int) isInteger "$val" ;;
    float) isFloat "$val" ;;
    date) isDate "$val" ;;
    string) return 0 ;;
    *) return 1 ;;
  esac
}

# Check primary-key uniqueness by consulting the .idx file
# Returns 0 if unique (i.e., not present), 1 if present
isPrimaryKeyUnique(){
  local db="$1"; local table="$2"; local val="$3"
  local idx="$DB_ROOT/$db/$table$IDX_EXT"
  if [ ! -f "$idx" ]; then
    return 0
  fi
  # exact match check
  if grep -Fxq -- "$val" "$idx" 2>/dev/null; then
    return 1
  fi
  return 0
}

# Create index file if missing (safe initializer)
ensureIndexFile(){
  local db="$1"; local table="$2"
  local idx="$DB_ROOT/$db/$table$IDX_EXT"
  if [ ! -f "$idx" ]; then
    : > "$idx"
  fi
}

# Simple confirm prompt. Default is 'no' unless second arg set to 'y'.
# Usage: prompt_confirm "Really delete? (y/N): " n
prompt_confirm(){
  local prompt_text="${1:-Are you sure? (y/N): }"
  local default_answer="${2:-n}"
  local ans
  read -r -p "$prompt_text" ans
  ans="${ans:-$default_answer}"
  [[ "$ans" =~ ^[Yy]$ ]]
}

# Validate metadata file format: ensures header exists, column names/types valid,
# and at most one primary key defined.
validate_meta_file(){
  local meta="$1"
  if [ ! -f "$meta" ]; then
    return 1
  fi
  local header
  header=$(sed -n '1p' "$meta" || echo "")
  [ -n "$header" ] || return 1
  IFS="$DELIM" read -r -a parts <<< "$header"
  local pkCount=0
  local part cname ctype cpk
  for part in "${parts[@]}"; do
    IFS=':' read -r cname ctype cpk <<< "$part"
    if ! validateName "$cname"; then
      return 1
    fi
    case "$ctype" in int|string|float|date) ;; *) return 1;; esac
    if [ "${cpk:-}" = "PK" ]; then
      pkCount=$((pkCount+1))
    fi
  done
  # Require exactly one primary key column for table integrity
  if [ "$pkCount" -ne 1 ]; then
    return 1
  fi
  return 0
}

# export functions for subshells that source helpers then call functions
export -f validateName isExsist isDBExists isTableExists trim isPositiveInteger isInteger isFloat isDate validateValueByType isPrimaryKeyUnique ensureIndexFile prompt_confirm validate_meta_file
 
# Ensure values do not contain the field delimiter
validateNoDelimiter(){
  local v="$1"
  if [[ "$v" == *"$DELIM"* ]]; then
    return 1
  fi
  return 0
}

export -f validateNoDelimiter
