#!/bin/bash

max=$1
file_to_execute=$2

if [ $# != 2 ]
then
  echo "Expected number of peers and file to execute. Use the following syntax:"
  echo "  ./Firefly-launcher.sh number_of_peers file_to_execute"
else
  killall lua
  sleep 1

  for (( n=1;n<=$max;n++ ))
  do
    rm $n.log > /dev/null 2>&1
    lua $file_to_execute $n $max &
  done
fi