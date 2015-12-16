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
    python3 Parser-ultimate.py -i ${input_file}
    echo "Output written on Parsed-logs/$input_file-cl-parsed.txt"
    echo "Output written on Parsed-logs/$input_file-ewl-parsed.txt\n\n\n"
  else
    echo "Logs/$input_file.txt were not parsed. Assuming the following files exists:"
    echo "  1. Parsed-logs/$input_file-cl-parsed.txt"
    echo "  2. Parsed-logs/$input_file-ewl-parsed.txt\n\n"
  fi
  # trick found on http://stackoverflow.com/questions/12328603/how-to-pass-command-line-argument-to-gnuplot#12330483
  output1="Plots/$input_file-cl.pdf"
  input1="Parsed-logs/$input_file-cl-parsed.txt"
  echo "Plotting $input1 ...\n"
  gnuplot -e "datafile='${input1}'; outputname='${output1}'" Gnuplot-cl.gp
  echo "Plot saved as $output1.\n\n\n"


  output2="Plots/$input_file-ewl.pdf"
  input2="Parsed-logs/$input_file-ewl-parsed.txt"
  echo "Plotting $input2 ...\n"
  gnuplot -e "datafile='${input2}'; outputname='${output2}'" Gnuplot-ewl.gp
  echo "Plot saved as $output2.\n\n\n"

  open ${output1}
  open ${output2}
fi