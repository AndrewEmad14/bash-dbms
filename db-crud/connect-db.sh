#!/bin/bash

source ./table-crud/tableMain.sh

connectToDatabase(){

  echo "Please enter your db name you wish to connect to"
  read dbName;
  if  ! isExsist $dbName ; then
    echo "database doesnt exsist"
  else
    echo "connected to $dbName database"
    runTableCRUD $dbName
    
  fi
}