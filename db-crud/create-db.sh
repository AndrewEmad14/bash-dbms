#!/bin/bash
source ./helpers/dbValidations.sh


createDatabase(){
  echo "Please enter your db name, it must contain only underscore and lowercase letters:"
  read dbName;
  if  isExsist $dbName ; then
    echo "database already exsist"
  elif ! validateName $dbName ; then
    echo "invalid format please try again"
  else
    mkdir ./databases/$dbName
    echo "data base created sucessfully"
  fi
}
