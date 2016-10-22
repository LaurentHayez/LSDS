set term pdf font "Helvetica, 8"

# some line types with different colors, you can use them by using line styles in the plot command afterwards (linestyle X)
set style line 1 lt 1 lc rgb "#FF0000" lw 7 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 7 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 7 # blue
set style line 4 lt 1 lc rgb "#000000" lw 7 # black
set style line 5 lt 1 lc rgb "#CD00CD" lw 7 # purple
set style line 6 lt 1 lc rgb "#FFFF00" lw 7 # yellow
set style line 7 lt 3 lc rgb "#000000" lw 7 # black, dashed line

set output "Indegree.pdf"
set title "Indegree"

# indicates the labels
set ylabel "number of peers"
set xlabel "indegree"

# set the grid on
set grid x y

# set graphic as histogram
set style data histogram
set style histogram clustered gap 1
#set style data histogram
#set style histogram cluster gap 1
set style fill solid border -1
set boxwidth 0.9

# set the key, options are top/bottom and left/right
set key top right

# indicates the ranges
set yrange [0:] # example of a closed range (points outside will not be displayed)
set xrange [-1:20] # example of a range closed on one side only, the max will determined automatically

plot for [COL=2:6:2] 'Logs/log_indegree.dat' using COL:xtic(1) title columnheader #"H=0 and S=0"; u 4:xtic(1) title "H=4 and S=0"; u 6:xtic(1) title "H=0 and S=4"
     #'Logs/log_indegree_H4_S0.dat' using 2:xtic(1) title "H=4 and S=0"# title 'Hello'

# $1 is column 1. You can do arithmetics on the values of the columns
