#!/usr/bin/env bash
set -euo pipefail

# Table main menu and dispatcher
# runTableCRUD <db_name> - interactive table-level CRUD menu for the connected database

# ensure config is loaded
if [ -z "${DB_ROOT:-}" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"
fi

# source table actions
source "$(dirname "${BASH_SOURCE[0]}")/create-table.sh"
source "$(dirname "${BASH_SOURCE[0]}")/list-tables.sh"
source "$(dirname "${BASH_SOURCE[0]}")/insert-into-table.sh"
source "$(dirname "${BASH_SOURCE[0]}")/select-from-table.sh"
source "$(dirname "${BASH_SOURCE[0]}")/drop-table.sh"
source "$(dirname "${BASH_SOURCE[0]}")/delete-table.sh"
source "$(dirname "${BASH_SOURCE[0]}")/update-table.sh"
# Stubs for not-yet-implemented actions; keeps the menu safe to use


runTableCRUD(){
  local DB_NAME="${1:-}"
  if [ -z "$DB_NAME" ]; then
    echo "runTableCRUD: missing database name" >&2
    return 1
  fi

  while true; do
    echo "Welcome To Table CRUD (DB: $DB_NAME)"
    echo "1- Create Table"
    echo "2- List Tables"
    echo "3- Drop Table"
    echo "4- Insert Into Table"
    echo "5- Select From Table"
    echo "6- Delete From Table"
    echo "7- Update Table"
    echo "8- Exit"

    read -p "Please Enter Your Choice: " choice

    case $choice in
        1)
            createTable "$DB_NAME"
            ;;
        2)
            listTables "$DB_NAME"
            ;;
        3)
            dropTable "$DB_NAME"
            ;;
        4)
            insertIntoTable "$DB_NAME"
            ;;
        5)
            selectFromTable "$DB_NAME"
            ;;
        6)
            deleteFromTable "$DB_NAME" 
            ;;
        7)
            updateTable "$DB_NAME"
            ;;
        8)
            return 0
            ;;
        *)
            echo "Invalid Choice, Please Try Again."
            ;;
    esac
  done
}

export -f runTableCRUD
