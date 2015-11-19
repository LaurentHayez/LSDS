set term pdf font "Helvetica, 8"

# some line types with different colors, you can use them by using line styles in the plot command afterwards (linestyle X)
set style line 1 lt 1 lc rgb "#FF0000" lw 7 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 7 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 7 # blue
set style line 4 lt 1 lc rgb "#000000" lw 7 # black
set style line 5 lt 1 lc rgb "#CD00CD" lw 7 # purple
set style line 6 lt 1 lc rgb "#FFFF00" lw 7 # yellow
set style line 7 lt 3 lc rgb "#000000" lw 7 # black, dashed line

set output "plots/task3-2-cluster.pdf"
set title "Stale references"

# indicates the labels
set ylabel "Stale references as a function of time"
set xlabel "time"

# set the grid on
set xtics 20
set ytics 5
#set grid xtics
set grid xtics ytics

# set graphic as histogram
#set style data histogram
#set style histogram clustered gap 1
#set style data histogram
#set style histogram cluster gap 1
#set style fill solid border -1
#set boxwidth 1.5

# set the key, options are top/bottom and left/right
set key top right

# indicates the ranges
set yrange [0:] # example of a closed range (points outside will not be displayed)
set xrange [-1:] # example of a range closed on one side only, the max will determined automatically

plot 'ParsedLogs/parsed_stale_refs.txt' u ($1):($2) with lines linestyle 1 title 'Stabilization: 2sec\nFixing fingers: 5sec\nChecking stale refs: 20sec'

# $1 is column 1. You can do arithmetics on the values of the columns
