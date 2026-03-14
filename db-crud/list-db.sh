#!/bin/bash
set -euo pipefail

if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi

listDataBases(){
  ls -1 "$DB_ROOT"
}
