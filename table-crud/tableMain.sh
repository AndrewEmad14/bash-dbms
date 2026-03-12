#!/bin/bash
# - Create Table 
# - List Tables
# - Drop Table
# - Insert into Table
# - Select From Table
# - Delete From Table
# - Update Table

runTableCRUD(){
  while [ true ]; do
    echo "Welcome To Table CRUD"
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
            createTable
            ;;
        2)
            listTables
            ;;
        3)
            dropTable
            ;;
        4)
            insertIntoTable
            ;;
        5)
            selectFromTable
            ;;
        6)
            deleteFromTable
            ;;
        7)
            updateTable
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


