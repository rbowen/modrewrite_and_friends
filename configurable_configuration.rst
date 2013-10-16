.. _part conditionalconfiguiration:

Conditional Configuration
=========================

Introduction
------------

While the Apache httpd configuration files have always had some ways to make things conditional, with the advent of version 2.4, there's an explosion in the ways that you can make your configuration file reactive and programmable. That is, you can make your configuration more responsive to the specifics of the request that it servicing.

In this part of the book, we discuss some of this functionality. Some of it is specific to version 2.4 and later, while some of it has been available for years.

\*Match Directive
-------------------

FilesMatch, RedirectMatch, etc.

.. _IfDefine:

IfDefine
--------

.. index:: IfDefine

The ``IfDefine`` directive provides a way to make blocks of your
configuration file optional, depending on the presence, or absence, of
an appropriate command-line switch. Specifically, a configuration block
wrapped in an ``<IfDefine XYZ>`` container will be invoked if and only
if the server is started up with a ``-D XYZ`` command line switch.

Consider, for example a configuration as follows:

::

    <IfDefine TEST>
        ServerName test.example.com
    </IfDefine>
    <IfDefine !TEST>
        ServerName www.example.com
    </IfDefine>

Now, you can start the server with a ``-D TEST`` command line option:

::

    httpd -D TEST -k restart

This will result in the first of the two ``IfDefine`` blocks being
loaded. Conversely, if you omit the ``-D TEST`` flag, the server will start
with the second of the two ``IfDefine`` blocks loaded.

This gives the ability to keep several configurations in the same file,
and load various components on demand. You could even deploy the same
configuration file to several different servers, but start each with
different command line flags (you can specify more than one ``-D`` flag
at startup) to start the servers up in different configurations.

``<IfDefine>`` blocks can be nested, so that you can combine several
conditions, as seen in this example from the docs:

::

    <IfDefine ReverseProxy>
        LoadModule proxy_module   modules/mod_proxy.so
        LoadModule proxy_http_module modules/mod_proxy_http.so
        <IfDefine UseCache>
            LoadModule cache_module modules/mod_cache.so
            <IfDefine MemCache>
                LoadModule mem_cache_module modules/mod_mem_cache.so
            </IfDefine>
            <IfDefine !MemCache>
                LoadModule cache_disk_module modules/mod_cache_disk.so
            </IfDefine>
        </IfDefine>
    </IfDefine>

You could then, for example, start the server up with:

    httpd -DReverseProxy -DUseCache -DMemCache -k restart

(The space between ``-D`` and the flag is optional.)

.. _Define:

Define
------

.. index:: Define

New with the 2.3 (and later) version of the server is the ``Define``
directive, which lets you define variables within the configuration
file, which can then be used later on in the configuration, either as
part of a configuration directive, or in an ``<IfDefine ...>``
directive.

Consider this variation on the earlier example:

::

    <IfDefine TEST>
        Define servername test.example.com
    </IfDefine>
    <IfDefine !TEST>
        Define servername www.example.com
        Define SSL
    </IfDefine>

    DocumentRoot /var/www/${servername}/htdocs

A variable ``VAR`` defined with the ``Define`` directive can then be used later
using the ``${VAR}`` syntax, as shown here. In the case where no value
is given (see the line ``Define SSL``) the variable is set to ``TRUE``,
which can then be tested later using an ``<IfDefine>`` test.

In this example, as before, the server should be started with a
``-DTEST`` command line option to use the first definition of
``servername`` and without it to use the second.

Or you can use a ``Define`` directive to define something, such as a
file path, which is then used several times in the configuration:

::

    Define docroot /var/www/vhosts/www.example.com

    DocumentRoot ${docroot}

    <Directory ${docroot}>
        Require all granted
    </Directory>

<If>, <Elsif>, and <Else>
-------------------------

.. index:: If
.. index:: <If>

New in Apache httpd 2.4 is the ability to put ``<If>`` blocks in your configuration file to make it truly conditional. This provides a level of flexibility that was never before available.

Whereas the ``<IfDefine>`` and ``<Define>`` directives are evaluated at
server startup time, ``<If>`` is evaluated at request time, giving you
the chance to make configuration dependant on values that may change
from one HTTP request to another. Naturally, this results in some
request-time overhead, but the flexibility that you gain may be worth
this to you in some situations.

Consider the following examples to give you some ideas:

Canonical hostname
``````````````````

.. index:: Canonical Hostname

In many situations, it is desirable to enforce a particular hostname on
your website. For example, if you are setting cookies, you need to
ensure that those cookies are valid for all requests to your site, which
requires that the hostname being accessed match the hostname on the
cookie itself. So, when someone accesses your site using the hostname
``example.com``, you want to redirect that request to use the hostname
``www.example.com``.

In previous versions of httpd, you may have used ``mod_rewrite`` to
perform this redirection, but ``<If>`` provides a more intuitive syntax:

::

    # Compare the host name to example.com and 
    # redirect to www.example.com if it matches
    <If "%{HTTP_HOST} == 'example.com'">
        Redirect permanent / http://www.example.com/
    </If>

Image hotlinking
````````````````

.. index:: Image Hotlinking
.. index:: Hotlinking

You may wish to prevent another website from embedding your images in
their pages - so-called image hotlinking. This is usually done by
comparing the HTTP_REFERER variable on a request to these images to
ensure that the request originated within a page on your site:

::

    # Images ...
    <FilesMatch "\.(gif|jpe?g|png)$">
        # Check to see that the referer is right
        <If "%{HTTP_REFERER} !~ /example.com/" >
            Require all denied
        </If>
    </FilesMatch>

.. todo:: More examples

mod_macro
---------

.. index:: mod_macro

``mod_macro`` has been around for a while, but with the 2.4 version of
the server it is now one of the modules that comes with the server
itself, rather than being a third-party module obtained and installed
separately.

It provides the ability - as the name suggests - to create macros within
your configuration file, which can then be invoked multiple times, in
order to produce several similar configuration blocks. Parameters can be
provided to fill in the variables in those macros.

Macros are evaluated at server startup time, and the resulting
configuration is then loaded as though it was a static configuration
file on disk.

mod_proxy_express
-----------------

mod_vhost_alias
---------------

Conditional logging
-------------------

env=
````

.. todo:: Using rewrite and [E] to effect env= conditional logging

Per-module logging
``````````````````

Per-directory logging
`````````````````````

Piped logging
`````````````


