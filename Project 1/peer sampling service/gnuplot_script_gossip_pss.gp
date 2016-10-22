set term pdf font "Helvetica, 8"

# some line types with different colors, you can use them by using line styles in the plot command afterwards (linestyle X)
set style line 1 lt 1 lc rgb "#FF0000" lw 7 # red
set style line 2 lt 1 lc rgb "#00FF00" lw 7 # green
set style line 3 lt 1 lc rgb "#0000FF" lw 7 # blue
set style line 4 lt 1 lc rgb "#000000" lw 7 # black
set style line 5 lt 1 lc rgb "#CD00CD" lw 7 # purple
set style line 6 lt 1 lc rgb "#FFFF00" lw 7 # yellow
set style line 7 lt 3 lc rgb "#000000" lw 7 # black, dashed line

set output "Gossip_pss.pdf"
set title "Anti entropy and rumor mongering combined\n using the PSS"

# indicates the labels
set xlabel "time (seconds)"
set ylabel "percentage of infected peers"

# set the grid on
set grid x y

# set the key, options are top/bottom and left/right
set key bottom right

# indicates the ranges
set yrange [0:] # example of a closed range (points outside will not be displayed)
set xrange [0:] # example of a range closed on one side only, the max will determined automatically

plot "parsed_log_f4_htl3_H0_S0.txt" u ($1):(100*$3) with lines linestyle 1 title "H=0, S=0",\
     "parsed_log_f4_htl3_H0_S4.txt" u ($1):(100*$3) with lines linestyle 2 title "H=0, S=4",\
     "parsed_log_f4_htl3_H2_S2.txt" u ($1):(100*$3) with lines linestyle 3 title "H=2, S=2",\
     "parsed_log_f4_htl3_H4_S0.txt" u ($1):(100*$3) with lines linestyle 4 title "H=4, S=0"
