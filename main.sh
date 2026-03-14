#!/bin/bash
set -euo pipefail

# load configuration and create databases root if missing
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
init_db

# source DB CRUD modules
source "$(dirname "${BASH_SOURCE[0]}")/db-crud/create-db.sh"
source "$(dirname "${BASH_SOURCE[0]}")/db-crud/drop-db.sh"
source "$(dirname "${BASH_SOURCE[0]}")/db-crud/list-db.sh"
source "$(dirname "${BASH_SOURCE[0]}")/db-crud/connect-db.sh"

runDBMS(){
    echo "Welcome To DBMS"
    echo "1- Create Database"
    echo "2- List Databases"
    echo "3- Connect To Database"
    echo "4- Drop Database"
    echo "5- Exit"

    read -p "Please Enter Your Choice: " choice

    case $choice in
        1)
            createDatabase
            ;;
        2)
            listDataBases
            ;;
        3)
            connectToDatabase
            ;;
        4)
            dropDatabase
            ;;
        5)
            exit 0
            ;;
        *)
            echo "Invalid Choice, Please Try Again."
            ;;
    esac
}

while true; do
  runDBMS
  echo "---------------------------------------------------------"
done
