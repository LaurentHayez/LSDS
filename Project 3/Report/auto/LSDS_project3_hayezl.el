(TeX-add-style-hook
 "LSDS_project3_hayezl"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("article" "a4paper" "11pt")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("inputenc" "utf8") ("fontenc" "T1") ("geometry" "top=3cm" "bottom=3cm" "left=3.2cm" "right=3.2cm") ("xcolor" "usenames" "dvipsnames") ("algorithm" "section") ("enumitem" "inline") ("babel" "english")))
   (add-to-list 'LaTeX-verbatim-environments-local "lstlisting")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperref")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "lstinline")
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
    "csquotes"
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
    "sec:impl-skel"
    "fig:repr-phi"
    "alg:firefly-skeleton"
    "sec:phase-ad-phase-de"
    "sec:implementation"
    "alg:firefly-phase"
    "sec:analysis-protocols"
    "fig:pa-sync-d1"
    "fig:pa-sync-d2"
    "fig:pa-sync-d5"
    "fig:pd-sync-d1"
    "fig:pd-sync-d2"
    "fig:pd-sync-d5"
    "sec:adapt-ermentr-model"
    "sec:implementation-1"
    "alg:adapt-er"
    "sec:analysis-protocol-er"
    "fig:er-sync"
    "fig:er-ewl"
    "fig:er-cl"
    "sec:analys-prot-under-churn"
    "fig:er-churn-sync"
    "fig:er-churn-ewl"
    "fig:er-churn-cl"
    "sec:conclusion")))

