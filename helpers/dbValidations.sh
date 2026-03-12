#!/bin/bash

# please note the the one and zeros are reversed here since the status code for success is zero

validateName(){
  [[ "$1" =~ ^[a-z][a-z0-9_]*$ ]]
}

isExsist(){
  test -e ./databases/$1 
}

