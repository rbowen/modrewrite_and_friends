#!/bin/sh

pdflatex book.tex
pdflatex book.tex
pdflatex book.tex
makeindex book.idx
makeindex book.idx
pdflatex book.tex
makeindex book.idx
dvipdf book.dvi

/opt/local/bin/latex2html -split 3 book.tex
/opt/local/bin/latex2html -split 0 -dir single -mkdir -nonavigation book.tex
./fixup_html.pl

cd book
perl -pi -le 's!file:/opt/local/share/lib/latex2html/!!' *.html
scp *.* sycamore.rcbowen.com:/var/www/vhosts/rewrite.drbacchus/book

