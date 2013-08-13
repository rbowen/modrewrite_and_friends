Introduction
============

Introduction
------------

In the first version of this book,
**The Definitive Guide to Apache mod_rewrite**
<http://drbacchus.com/book/rewrite>,
which was published in 2006, I only talked about mod_rewrite. But,
with the release of Apache httpd 2.4 in February of 2012, the
world of complex URL mapping is so much bigger than that.
In addition to mod_rewrite, a number of
new standard modules have joined the game, as well as a number of
powerful core features, which make mod_rewrite just one of many tools
in your bag of tricks.

And so the scope of this book has expanded to include not merely URL
rewriting, but also methods for munging (modifying) content, and
dynamic conditional configuration. In many cases, these techniques make
mod_rewrite unnecessary, or, at least, provide easier alternatives, so
they fit the scope of the book very well.

These techniques include mod_substitute, mod_proxy_html, the ``Define``
directive, the ``<If>`` container, mod_macro, and many more. Along the
way, we'll also discuss the various parts of URL mapping, the
understanding of which allows you to avoid using these more complicated
techniques.

While all of these are covered in the formal documentation
<http://httpd.apache.org/docs/current>, this book offers a companion
to hold your hand and offer you more in depth assistance in your journey
towards Apache httpd mastery.

About this book
```````````````

This book has a long and storied history. It has been written in LaTeX,
using TexStudio. It has been written using markdown and docbook, using
vim, and who knows what else. This particular version was written using
reStructuredText (See ``http://docutils.sourceforge.net/rst.html`` for
details) and so should be available in pretty much any format you care
to see it in.

You can always obtain the most recent version of
the book at ``http://rewrite.rcbowen.com/``, and you'll usually be able to buy a fairly recent version in the Amazon Kindle store. Some day, there will hopefully be a printed version, too.

If you'd like to get involved in the creation of this book, or if you'd like to tell me about something that needs fixed, Fork it on GitHub <https://github.com/rbowen/modrewrite_and_friends> and submit pull requests. If you don't know what that means, you are welcome to submit errata to ``rbowen@rcbowen.com``, and some day there will be a handy way to do this on the website. Not today.

This book is a work in progress. If you purchased the book in electronic
form, you should be eligible to receive updates from wherever you bought
it. If you're not, send me your email receipt (rbowen@rcbowen.com), 
and I'll send you an updated version.

A brief word about the documentation. The official docs, at ``http://httpd.apache.org/docs/``, are great, and are the work of many dedicated people. I'm one of many. This book is intended to augment those docs, and not replace them. If it appears sometimes that I have copied shamelessly from the documentation, I humbly ask you to remember that I participated in writing those docs, and the edits flowed both directions -- that is, sometimes it was the docs that shamelessly copied from the book.

About the author
````````````````

Rich Bowen has been involved on the Apache http server documentation
since about 1998. He is also the author of **Apache Cookbook**, and **The
Definitive Guide to Apache mod_rewrite**. You can frequently find him in
#httpd, on ``irc.freenode.net``. under the name of DrBacchus.

Rich works at Red Hat, in the OSAS (Open Source and Standards) group,
where he works with the OpenStack community. See
<http://openstack.redhat.com/> for details.

He lives in Lexington, Kentucky, with his wife and kids. If you want a cat, drop by any time.

Acknowledgements
````````````````

Many thanks to everyone that works on the reStructuredText project, or
on Sphinx, or any of the other tools that I used to create this
document. Particular thanks to Kushal Dal for pointing me to RST in the
first place.

Thanks to ``fajita``, and the other regulars on #httpd (on the ``irc.freenode.net`` network). ``fajita`` is my research assistant, and knows more than everyone else on the channel put together. And the folks on #ahd who keep me sane. Or insane. Depending on how you measure. A warm hog to each of you.

None of this would be possible without mod_rewrite
itself, so a big thank you to Ralf Engelschall for creating it, and
all the many people who have worked on the code and documentation since
then.

Finally, and most importantly, thanks to my beautiful wife, and to Rhi,
Hammy, and Daisy, my multi-talented children, for being so wonderful 
in every way. What would I do without you?

