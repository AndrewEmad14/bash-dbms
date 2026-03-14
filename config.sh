#!/usr/bin/env bash
set -euo pipefail

# Base directory of the bash-dbms package (this file's directory)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Databases root directory (inside BASE_DIR)
DB_ROOT="$BASE_DIR/databases"

# Field delimiter and extensions
DELIM='|'
META_EXT='.meta'
DATA_EXT='.data'
IDX_EXT='.idx'

# Initialize databases directory
init_db() {
  mkdir -p "$DB_ROOT"
}

export BASE_DIR DB_ROOT DELIM META_EXT DATA_EXT IDX_EXT
