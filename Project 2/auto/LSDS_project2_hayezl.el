(TeX-add-style-hook
 "LSDS_project2_hayezl"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "a4paper" "11pt")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("inputenc" "utf8") ("fontenc" "T1") ("geometry" "top=3cm" "bottom=3cm" "left=3.2cm" "right=3.2cm") ("xcolor" "usenames" "dvipsnames") ("algorithm" "section") ("enumitem" "inline") ("babel" "english")))
   (add-to-list 'LaTeX-verbatim-environments-local "lstlisting")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperref")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "url")
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art11"
    "inputenc"
    "fontenc"
    "graphicx"
    "wrapfig"
    "geometry"
    "lmodern"
    "fancyhdr"
    "color"
    "colortbl"
    "xcolor"
    "amsmath"
    "amssymb"
    "mathrsfs"
    "amsthm"
    "pgf"
    "pgfplots"
    "tikz"
    "listings"
    "makeidx"
    "hyperref"
    "setspace"
    "manfnt"
    "multicol"
    "algorithm"
    "algorithmicx"
    "algpseudocode"
    "etoolbox"
    "array"
    "multirow"
    "longtable"
    "enumerate"
    "enumitem"
    "babel"
    "caption"
    "tabu")
   (TeX-add-symbols
    '("CodeDigits" 1)
    '("CodeBrackets" 1)
    "N"
    "Q"
    "R"
    "Z"
    "C")
   (LaTeX-add-labels
    "sec:introduction"
    "sec:base-chord-protocol"
    "sec:implementation-without-ft"
    "impl-fing-table"
    "sec:search-performances"
    "fig:search-basic-chord"
    "fig:search-perf-chord-fing-table"
    "fig:comp-search-chord"
    "sec:fault-tolerant-chord"
    "sec:impl-ft-chord"
    "sec:eval-ft-chord"
    "fig:Av-SR-stab"
    "fig:Av-SR-fix-fingers"
    "fig:Av-SR-check-finger"
    "sec:conclusion"
    "fig:Rec-SR-stab"
    "fig:Rec-SR-fix-fingers"
    "fig:Rec-SR-check-finger"
    "fig:Av-SR-fix-finger-am"
    "fig:Rec-SR-fix-finger-am"
    "fig:percentage-successfully-found-keys"
    "fig:search-perf-with-churn")))

