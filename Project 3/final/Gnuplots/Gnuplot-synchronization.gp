set term pdf font "Marion, 11"

# some line types with different colors, you can use them by using line styles in the plot command afterwards (linestyle X)
set style line 1 lt 1 lc rgb "#FF0000" lw 3 # red
set style line 2 lt 1 lc rgb "#556B2F" lw 1.5 # olive green
set style line 3 lt 1 lc rgb "#0000FF" lw 3 # blue
set style line 4 lt 1 lc rgb "#000000" lw 3 # black
set style line 5 lt 1 lc rgb "#CD00CD" lw 3 # purple
set style line 6 lt 1 lc rgb "#FFFF00" lw 3 # yellow
set style line 7 lt 3 lc rgb "#000000" lw 3 # black, dashed line
# Olive green color html: #556B2F

set output outputname
set title "Synchronization for the adaptive Ermentrout model with churn (64 nodes, delta = 5)"

# indicates the labels
set ylabel "Node id"
set xlabel "Time (s)"

# set
set grid x y

# set the key, options are top/bottom and left/right
set key top right

# indicates the ranges
set yrange [0:70] # example of a closed range (points outside will not be displayed)
set xrange [0:450] # example of a range closed on one side only, the max will determined automatically

set pointsize 0.1

plot datafile u ($1):($2) with points ls 2 pt 6 title "Flash emitted"

# $1 is column 1. You can do arithmetics on the values of the columns