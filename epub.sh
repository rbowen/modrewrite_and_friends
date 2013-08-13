#!/bin/sh

mv _templates/layout.html /tmp
cp ./layout.epub _templates/layout.html

make epub

mv /tmp/layout.html _templates/layout.html

echo Time to do the conversion dance in Calibre

