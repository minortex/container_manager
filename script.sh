#!/bin/bash

action=$1
name=$2
path=$3

if [ -z "$path" ]; then
  path=$(pwd)
fi

case $action in
  pull )
    wget -O $name.tar $path >> /dev/null 2>$1
    if [ $? -eq 0 ]; then
      echo "Successfully Downloaded. Begin exacting..."
      mkdir $name
      tar -xvf $name.tar -C $name >> /dev/null 2>$1
      rm $name.tar
      echo "Done."
    else
	  echo "Failed to download file."
	fi ;;
  create )
    runc create --bundle $path $name ;;
  run )
    runc run -d --bundle $path $name ;;
  stop )
    runc stop $name ;;
  help )
    echo "A simple script to use runc."
    echo -e "Usage: script.sh [actions] [name] [path/url]\n"
    echo -e "  actions:\n\tpull\n\tcreate\n\trun\n\tstop\n"
    echo "[name] and [url] must be specified. [path] can be blanked, will use current dir." ;;
  * )
    echo "bad argument." ;;
esac  
