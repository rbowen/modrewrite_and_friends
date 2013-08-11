#!/bin/sh

make html
scp -r ./_build/html/* sycamore.rcbowen.com:/var/www/vhosts/rewrite.drbacchus/book/
