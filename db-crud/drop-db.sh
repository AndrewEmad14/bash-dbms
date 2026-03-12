#!/bin/bash
source ./helpers/dbValidations.sh



dropDatabase(){
  echo "Please enter your db name you wish to drop"
  read dbName;
  if  ! isExsist $dbName ; then
    echo "database doesnt exsist"
  else
    rm  -r ./databases/$dbName
    echo "data base dropped"
  fi
}