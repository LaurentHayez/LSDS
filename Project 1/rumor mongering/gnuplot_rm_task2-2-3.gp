set term pdf font "Helvetica, 8"

# some line types with different colors, you can use them by using line styles in the plot command afterwards (linestyle X)
set style line 1 lt 1 lc rgb "#FF0000" lw 7 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 7 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 7 # blue
set style line 4 lt 1 lc rgb "#000000" lw 7 # black
set style line 5 lt 1 lc rgb "#CD00CD" lw 7 # purple
set style line 6 lt 1 lc rgb "#FFFF00" lw 7 # yellow
set style line 7 lt 3 lc rgb "#000000" lw 7 # black, dashed line

set output "plots/rm_plot_task2-2-3.pdf"
set title "Rumor Mongering \n #infected peer in function of #duplicates received"

# indicates the labels
set xlabel "number of duplicates received"
set ylabel "number of infected peers"

# set the grid on
 set grid x y

# set the key, options are top/bottom and left/right
set key bottom right

# indicates the ranges
set yrange [0:] # example of a closed range (points outside will not be displayed)
set xrange [0:] # example of a range closed on one side only, the max will determined automatically

plot "parsed_logs_rm/log_htl3_f2_parsed.txt" u ($1):($2) with lines linestyle 1 title "HTL=3, f=2",\
     "parsed_logs_rm/log_htl2_f3_parsed.txt" u ($1):($2) with lines linestyle 2 title "HTL=2, f=3",\
     "parsed_logs_rm/log_htl5_f5_parsed.txt" u ($1):($2) with lines linestyle 3 title "HTL=5, f=5",\
     "parsed_logs_rm/log_htl5_f2_parsed.txt" u ($1):($2) with lines linestyle 4 title "HTL=5, f=2",\
     "parsed_logs_rm/log_htl5_f8_parsed.txt" u ($1):($2) with lines linestyle 5 title "HTL=5, f=8",\
     "parsed_logs_rm/log_htl2_f5_parsed.txt" u ($1):($2) with lines linestyle 6 title "HTL=2, f=5"

# $1 is column 1. You can do arithmetics on the values of the columns
