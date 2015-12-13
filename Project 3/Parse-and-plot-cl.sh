#!/bin/zsh

# Author: Laurent Hayez
# Date: 05 dec 2015
# File: Parses the file given as argument and plots it (for emission window length)

input_file=$1
parse=$2

if [ $# != 2 ]
then
  echo "Invalid number of arguments. Use the following syntax:"
  echo "  ./Parse-and-plot-cl.sh <filename> <true/false>"
  echo "  Example: ./Parse-and-plot-cl.sh Firefly-data t"
else
  if [[ ${parse} == "t" ]]
  then
    echo "Parsing Logs/$input_file.txt"
    python3 Parser-cycle-lengths.py -i "Logs/$input_file.txt" -o "Parsed-logs/$input_file-cl-parsed.txt"
    echo "Output written on Parsed-logs/$input_file-cl-parsed.txt"
  else
    echo "Logs/$input_file.txt were not parsed. Assuming Parsed-logs/$input_file-cl-parsed.txt exists."
  fi
  # trick found on http://stackoverflow.com/questions/12328603/how-to-pass-command-line-argument-to-gnuplot#12330483
  output="Plots/$input_file-cl.pdf"
  input="Parsed-logs/$input_file-cl-parsed.txt"
  echo "Plotting $input"
  gnuplot -e "datafile='${input}'; outputname='${output}'" Gnuplot-cl.gp
  echo "Plot saved as $output"
  open ${output}
fi