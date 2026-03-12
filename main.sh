#!/bin/bash
# - Create Database
# - List Databases
# - Connect To Databases
# - Drop Database


source ./db-crud/create-db.sh
source ./db-crud/drop-db.sh
source ./db-crud/list-db.sh
source ./db-crud/connect-db.sh


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



while [ true ]; do
  runDBMS;
  echo "---------------------------------------------------------"
done
