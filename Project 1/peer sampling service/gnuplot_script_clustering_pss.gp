set term pdf font "Helvetica, 8"

# some line types with different colors, you can use them by using line styles in the plot command afterwards (linestyle X)
set style line 1 lt 1 lc rgb "#FF0000" lw 7 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 7 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 7 # blue
set style line 4 lt 1 lc rgb "#000000" lw 7 # black
set style line 5 lt 1 lc rgb "#CD00CD" lw 7 # purple
set style line 6 lt 1 lc rgb "#FFFF00" lw 7 # yellow
set style line 7 lt 3 lc rgb "#000000" lw 7 # black, dashed line

set output "Clustering.pdf"
set title "Cumulative distribution of\n the clustering factor"

# indicates the labels
set ylabel "proportion of peers"
set xlabel "Clustering"

#set logscale y

# set the grid on
set grid x y

# set the key, options are top/bottom and left/right
set key bottom right

# indicates the ranges
set yrange [0:] # example of a closed range (points outside will not be displayed)
set xrange [0:] # example of a range closed on one side only, the max will determined automatically

plot 'Logs/log_clustering_H0_S0.dat' u ($1):($2/50) with lines linestyle 1 title "H=0 and S=0",\
     'Logs/log_clustering_H0_S4.dat' u ($1):($2/50) with lines linestyle 2 title "H=0 and S=4",\
     'Logs/log_clustering_H4_S0.dat' u ($1):($2/50) with lines linestyle 3 title "H=4 and S=0"
