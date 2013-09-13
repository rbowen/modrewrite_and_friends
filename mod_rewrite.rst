.. _part mod_rewrite:

mod_rewrite
===========

Introduction to mod_rewrite
----------------------------

mod_rewrite is the power tool of Apache httpd URL mapping. Of course, sometimes you just need a screwdriver, but when you need the power tool, it's good to know where to find it.

mod_rewrite provides sophisticated URL via regular expressions, and the ability to do a variety of transformations,including, but not limited to, modification of the request URL. You can additionally return a variety of status codes, set cookies and environment variables, proxy requests to another server, or send redirects to the client.

In this chapter we'll cover mod_rewrite syntax and usage, and in the next chapter we'll give a variety of examples of using mod_rewrite in common scenarios.

Loading mod_rewrite
```````````````````

To use mod_rewrite in any context, you need to have the module loaded. If you're the server administrator, this means having the following line somewhere in your Apache httpd configuration:

::

    LoadModule rewrite_module modules/mod_rewrite.so


This tells httpd that it needs to load mod_rewrite at startup time, so as to make its functionality available to your configuration files.

If you are not the server administrator, then you'll need to ask your server administrator if the module is available, or experiment to see if it is. If you're not sure, you can test to see whether it's enabled in the following manner.

Create a subdirectory in your document directory. Let's call it `test_rewrite`

Create a file in that directory called `.htaccess` and put the following text in it:

::

    RewriteEngine on

Create another file in that directory called `index.html` containing the following text:

::

    <html>
    Hello, mod_rewrite
    </html>

Now, point your browser at that location:

::

    http://example.com/test_rewrite/index.html

You'll see one of two things. Either you'll see the words `Hello, mod_rewrite` in your browser, or you'll see the ominous words `Internal Server Error`. In the former case, everything is fine - mod_rewrite is loaded and your ``.htacces`` file worked just fine. If you got an `Internal Server Error`, that was httpd complaining that it didn't know what to do with the ``RewriteEngine`` directive, because mod_rewrite wasn't loaded.

If you have access to the server's error log file, you'll see the following in it:

::

    Invalid command 'RewriteEngine', perhaps misspelled or defined by a module not included in the server configuration


Which is httpd's way of saying that you used a directive (``RewriteEngine``) without first loading the module that defines that directive.

If you see the `Internal Server Error` message, or that log file message, it's time to contact your server administrator and ask if they'll load mod_rewrite for you.

However, this is fairly unlikely, since mod_rewrite is a fairly standard part of any Apache http server's bag of tricks.

RewriteEngine
`````````````

In the section above, we used the ``RewriteEngine`` directive without defining what it does.

The ``RewriteEngine`` directive enables or disables the runtime rewriting engine. The directive defaults to ``off``, so the result is that rewrite directives will be ignored in any scope where you don't have the following:

::

    RewriteEngine On

While we won't always include that in every example in this book, it should be assumed, from this point forward, that every use of mod_rewrite occurs in a scope where ``RewriteEngine`` has been turned on.

mod_rewrite in .htaccess files
-------------------------------

.. index:: htaccess files
.. index:: mod_rewrite in .htaccess files

Before we go any further, it's critical to note that things are different, in several important ways, if you have to use .htaccess files for configuration.

What are .htaccess files?
`````````````````````````

.htaccess files are per-directory configuration files, for use by people who don't have access to the main server configuration file. For the most part, you put configuration directives into .htaccess files just as you would in a ``<Directory>`` block in the server configuration, but there are some differences.

The most important of these differences is that the .htaccess file is consulted every time a resource is requested from the directory in question, whereas configurations placed in the main server configuration file are loaded once, at server startup. 

The positive side of this is that you can modify the contents of a .htaccess file and have the change take effect immediately, as of the next request received by the server.

The negative is that the .htaccess file needs to be loaded from the filesystem on every request, resulting in an incremental slowdown for every request. Additionally, because httpd doesn't know ahead of time what directories contain .htaccess files, it has to look in each directory for them, all along the path to the requested resource, which results in a slowdown that grows with the depth of the directory tree.

In Apache httpd 2.2 and earlier, .htaccess files are enabled by default - that is the configuration directive that enables them, ``AllowOverride``, has a default value of ``All``. In 2.4 and later, it has a default value of ``None``, so .htaccess files are disabled by default.

A typical configuration to permit the use of .htaccess files looks like:

::

    <Directory />
        AllowOverride None
    </Directory>

    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Options +FollowSymLinks
    </Directory /var/www/html>

That is to say, .htaccess files are disallowed for the entire filesystem, 
starting at the root, but then are permitted in the document directories.
This prevents httpd [#]_ from looking for .htaccess files in ``/``, ``/var``, 
and ``/var/www`` on the way to looking in ``/var/www/html``.

Note that in order to enable the use of mod_rewrite directives in
``.htaccess`` files, you also need to enable ``Options FollowSymLinks``.
A ``RewriteRule`` may be thought of as
a kind of symlink, because it allows you to serve content from other
directories via a rewrite. Thus, for reasons of security, it is
necessary to enable symlinks in order to use mod_rewrite.

Ok, so, what's the deal with mod_rewrite in .htaccess files?
`````````````````````````````````````````````````````````````

There are two major differences that you must be aware of before we proceed any further. The exact implications of these differences will become more apparent as we go, but I wouldn't want them to surprise you.

First, there are two directives that you cannot use in .htaccess files. These directives are ``RewriteMap`` and (prior to httpd 2.4) ``RewriteLog``. These must be defined in the main server configuration. The reasons for this will be discussed in greater length when we get to the sections about those directives :ref:`RewriteMap` and :ref:`RewriteLogging`, respectively.).

Second, and more importantly, the syntax of ``RewriteRule`` directives changes in .htaccess context in a way that you'll need to be aware of every time you write a ``RewriteRule``. Specifically, the directory path that you're in will be removed from the URL path before it is presented to the ``RewriteRule``.

The exact implications of this will become clearer as we show you examples. And, indeed, every example in this book will be presented in a form for the main config, and a form for .htaccess files, whenever there is a difference between the two forms. But we'll start with a simple example to illustrate the idea.

Some of this, you'll need to take on faith at the moment, since we've not yet introduced several of the concepts presented in this example, so please be patient for now.

Consider a situation where you want to apply a rewrite to content in the ``/images/puppies/`` subdirectory of your website. You have four options: You can put the ``RewriteRule`` in the main server configuration file; You can place it in a .htacess file in the root of your website; You can place it in a .htaccess file in the ``images`` directory; Or you can place it in a .htaccess file in the ``images/puppies`` directory.

Here's what the rule might look like in those various scenarios:

========================  ====
Location                  Rule
------------------------  ----
Main config               ``RewriteRule ^/images/puppies/(.*).jpg /dogs/$1.gif``
Root directory            ``RewriteRule ^images/puppies/(.*).jpg /dogs/$1.gif``
images directory          ``RewriteRule ^puppies/(.*).jpg /dogs/$1.gif``
images/puppies directory  ``RewriteRule ^(.*).jpg /dogs/$1.gif``
========================  ====

For the moment, don't worry too much about what the individual rules do.
Look instead at the URL path that is being considered in each rule, and
notice that for each directory that a .htaccess file is placed in, the directory path that ``RewriteRule`` may consider is relative to that directory, and anything above that becomes invisible for the purpose of mod_rewrite.

Don't worry too much if this isn't crystal clear at this point. It will become more clear as we proceed and you see more examples.

So, what do I do?
`````````````````

If you don't have access to the main server configuration file, as it the case for many of the readers of this book, don't despair. mod_rewrite is still a very powerful tool, and can be persuaded to do almost anything that you need it to do. You just need to be aware of its limitations, and adjust accordingly when presented with an example rule.

We aim to help you do that at each step along this journey.

.. index:: RewriteOptions
.. _RewriteOptions:

RewriteOptions
--------------

.. todo:: Write this section

.. index:: RewriteRule
.. _RewriteRule:

RewriteRule
-----------

We'll start the main technical discussion of mod_rewrite with the `RewriteRule` directive, as it is the workhorse of mod_rewrite, and the directive that you'll encounter most frequently.

`RewriteRule` performs manipulation of a requested URL, and along the way can do a number of additional things.

The syntax of a `RewriteRule` is fairly simple, but you'll find that exploring all of the possible permutations of it will take a while. So we'll provide a lot of examples along the way to illustrate.

If you learn best by example, you may want to jump back and forth between this section and `Rewrite Examples`_ to help you make sense of this all.

Syntax
``````

A `RewriteRule` directive has two required directives and optional flags. It looks like:

::

    RewriteRule PATTERN TARGET [FLAGS]

The following sections will discuss each of those arguments in great detail, but these are defined as:

PATTERN
    A regular expression to be applied to the requested URI.

TARGET
    What the URI will be rewritten to.

FLAGS
    Optional flags that modify the behavior of the rule.

Pattern
```````

The ``PATTERN`` argument of the ``RewriteRule`` is a regular expression that is applied to the URL path, or file path, depending on the context.

In VirtualHost context, or in server-wide context, ``PATTERN`` will be matched against the part of the URL after the hostname and port, and before the query string. For example, in the URL <http://example.com/dogs/index.html?dog=collie>, the pattern will be matched against ``/dogs/index.html``.

In Directory and htaccess context, ``PATTERN`` will be matched against the filesystem path, after removing the prefix that led the server to the current ``RewriteRule`` (e.g. either "dogs/index.html" or "index.html" depending on where the directives are defined).

Subsequent ``RewriteRule`` patterns are matched against the output of the last matching ``RewriteRule``.

It is assumed, at this point, that you've already read the chapter :ref:`Introduction to Regular Expressions`, and/or are familiar with what a regular expression is, and how to craft one.

Target
``````

The target of a ``RewriteRule`` can be one of the following:

A file-system path
''''''''''''''''''

Designates the location on the file-system of the resource to be delivered to the client. Substitutions are only treated as a file-system path when the rule is configured in server (virtualhost) context and the first component of the path in the substitution exists in the file-system

URL-path
''''''''

A DocumentRoot-relative path to the resource to be served. Note that mod_rewrite tries to guess whether you have specified a file-system path or a URL-path by checking to see if the first segment of the path exists at the root of the file-system. For example, if you specify a Substitution string of ``/www/file.html``, then this will be treated as a URL-path unless a directory named www exists at the root or your file-system (or, in the case of using rewrites in a .htaccess file, relative to your document root), in which case it will be treated as a file-system path. If you wish other URL-mapping directives (such as Alias) to be applied to the resulting URL-path, use the ``[PT]`` flag as described below.

Absolute URL
''''''''''''

If an absolute URL is specified, mod_rewrite checks to see whether the hostname matches the current host. If it does, the scheme and hostname are stripped out and the resulting path is treated as a URL-path. Otherwise, an external redirect is performed for the given URL. To force an external redirect back to the current host, see the ``[R]`` flag below.

\- (dash)
'''''''''

A dash indicates that no substitution should be performed (the existing path is passed through untouched). This is used when a flag (see below) needs to be applied without changing the path.

Flags
`````

.. index:: Flags
.. index:: RewriteRule: Flags

Flags modify the behavior of the rule. You may have zero or more flags, and the effect is cumulative. Flags may be repeated where appropriate. For example, you may set several environment variables by using several ``[E]`` flags, or set several cookies with multiple ``[CO]`` flags. Flags are separated with commas:

::

    [B,C,NC,PT,L]

There are a *lot* of flags. Here they are:

B - escape backreferences
'''''''''''''''''''''''''

.. index:: B flag
.. index:: Rewrite flags! B
.. index:: Flags! B


The `[B]` flag instructs `RewriteRule` to escape non-alphanumeric characters before applying the transformation.

mod_rewrite has to unescape URLs before mapping them, so backreferences are unescaped at the time they are applied. Using the B flag, non-alphanumeric characters in backreferences will be escaped. (See :ref:`backreferences` for discussion of backreferences.) For example, consider the rule:

::

    RewriteRule ^search/(.*)$ /search.php?term=$1

Given a search term of ``'x & y/z'``, a browser will encode it as ``'x%20%26%20y%2Fz'``, making the request ``'search/x%20%26%20y%2Fz'``. Without the B flag, this rewrite rule will map to ``'search.php?term=x & y/z'``, which isn't a valid URL, and so would be encoded as ``search.php?term=x%20&y%2Fz=``, which is not what was intended.

With the B flag set on this same rule, the parameters are re-encoded before being passed on to the output URL, resulting in a correct mapping to ``/search.php?term=x%20%26%20y%2Fz``.

Note that you may also need to set ``AllowEncodedSlashes`` to ``On`` to get this particular example to work, as httpd does not allow encoded slashes in URLs, and returns a 404 if it sees one.

This escaping is particularly necessary in a proxy situation, when the backend may break if presented with an unescaped URL.

C - chain
'''''''''

.. index:: C flag
.. index:: Rewrite flags! C
.. index:: Flags! C

The ``[C]`` or ``[chain]`` flag indicates that the RewriteRule is chained to the next rule. That is, if the rule matches, then it is processed as usual and control moves on to the next rule. However, if it does not match, then the next rule, and any other rules that are chained together, will be skipped.

CO - cookie
'''''''''''

.. index:: CO flag
.. index:: Rewrite flags! CO
.. index:: Flags! CO

The ``[CO]``, or ``[cookie]`` flag, allows you to set a cookie when a particular RewriteRule matches. The argument consists of three required fields and four optional fields.

The full syntax for the flag, including all attributes, is as follows:

::

    [CO=NAME:VALUE:DOMAIN:lifetime:path:secure:httponly]

You must declare a name, a value, and a domain for the cookie to be set.

Domain
""""""

The domain for which you want the cookie to be valid. This may be a hostname, such as www.example.com, or it may be a domain, such as .example.com. It must be at least two parts separated by a dot. That is, it may not be merely .com or .net. Cookies of that kind are forbidden by the cookie security model.
You may optionally also set the following values:

Lifetime
""""""""

The time for which the cookie will persist, in minutes.
A value of 0 indicates that the cookie will persist only for the current browser session. This is the default value if none is specified.

Path
""""

The path, on the current website, for which the cookie is valid, such as ``/customers/`` or ``/files/download/``.
By default, this is set to ``/`` - that is, the entire website.

Secure
""""""

If set to secure, true, or 1, the cookie will only be permitted to be translated via secure (https) connections.

httponly
""""""""

If set to HttpOnly, true, or 1, the cookie will have the HttpOnly flag set, which means that the cookie will be inaccessible to JavaScript code on browsers that support this feature.

Example
"""""""

Consider this example:

::

    RewriteEngine On
    RewriteRule ^/index\.html - [CO=frontdoor:yes:.example.com:1440:/]

In the example give, the rule doesn't rewrite the request. The '-' rewrite target tells mod_rewrite to pass the request through unchanged. Instead, it sets a cookie called 'frontdoor' to a value of 'yes'. The cookie is valid for any host in the .example.com domain. It will be set to expire in 1440 minutes (24 hours) and will be returned for all URIs (i.e., for the path '/').

DPI - discardpath
'''''''''''''''''

.. index:: Rewrite flags! DPI
.. index:: DPI flag
.. index:: Flags! DPI

The DPI flag causes the ``PATH_INFO`` portion of the rewritten URI to be discarded.

This flag is available in version 2.2.12 and later.

In per-directory context, the URI each ``RewriteRule`` compares against is the concatenation of the current values of the URI and ``PATH_INFO``.

The current URI can be the initial URI as requested by the client, the result of a previous round of mod_rewrite processing, or the result of a prior rule in the current round of mod_rewrite processing.

In contrast, the ``PATH_INFO`` that is appended to the URI before each rule reflects only the value of ``PATH_INFO`` before this round of mod_rewrite processing. As a consequence, if large portions of the URI are matched and copied into a substitution in multiple ``RewriteRule`` directives, without regard for which parts of the URI came from the current ``PATH_INFO``, the final URI may have multiple copies of ``PATH_INFO`` appended to it.

Use this flag on any substitution where the ``PATH_INFO`` that resulted from the previous mapping of this request to the filesystem is not of interest. This flag permanently forgets the ``PATH_INFO`` established before this round of mod_rewrite processing began. ``PATH_INFO`` will not be recalculated until the current round of mod_rewrite processing completes. Subsequent rules during this round of processing will see only the direct result of substitutions, without any ``PATH_INFO`` appended.

E - env
'''''''

.. index:: Rewrite flags! E
.. index:: E flag
.. index:: Flags! E

With the ``[E]``, or ``[env]`` flag, you can set the value of an environment variable. Note that some environment variables may be set after the rule is run, thus unsetting what you have set.

The full syntax for this flag is:

::

    [E=VAR:VAL] 
    [E=!VAR]

VAL may contain backreferences (See section :ref:`backreferences`) (``$N`` or ``%N``) which will be expanded.

Using the short form

::

    [E=VAR]

you can set the environment variable named VAR to an empty value.

The form

::

    [E=!VAR]

allows to unset a previously set environment variable named VAR.

Environment variables can then be used in a variety of contexts, including CGI programs, other RewriteRule directives, or CustomLog directives.

The following example sets an environment variable called 'image' to a value of '1' if the requested URI is an image file. Then, that environment variable is used to exclude those requests from the access log.

::

    RewriteRule \.(png|gif|jpg)$ - [E=image:1]
    CustomLog logs/access_log combined env=!image

Note that this same effect can be obtained using SetEnvIf. This technique is offered as an example, not as a recommendation.

The ``[E]`` flag may be repeated if you want to set more than one environment variable at the same time:

::

    RewriteRule \.pdf$ [E=document:1,E=pdf:1,E=done]

END
'''

.. index:: END flag
.. index:: Rewrite flags! END
.. index:: Flags! END

Although the flags are presented here in alphabetical order, it makes more sense to go read the section about the L flag first (\ref{lflag}) and then come back here.

Using the ``[END]`` flag terminates not only the current round of rewrite processing (like ``[L]``) but also prevents any subsequent rewrite processing from occurring in per-directory (htaccess) context.

This does not apply to new requests resulting from external redirects.

F - forbidden
'''''''''''''

.. index:: Rewrite flags!F
.. index:: Flags!F
.. index:: F flag

Using the ``[F]`` flag causes the server to return a 403 Forbidden status code to the client. While the same behavior can be accomplished using the Deny directive, this allows more flexibility in assigning a Forbidden status.

The following rule will forbid ``.exe`` files from being downloaded from your server.

::

    RewriteRule \.exe - [F]

This example uses the "-" syntax for the rewrite target, which means that the requested URI is not modified. There's no reason to rewrite to another URI, if you're going to forbid the request.

When using ``[F]``, an ``[L]`` is implied - that is, the response is returned immediately, and no further rules are evaluated.

G - gone
''''''''

.. index:: G flag
.. index:: Rewrite flags!G
.. index:: Flags!G

The ``[G]`` flag forces the server to return a 410 Gone status with the response. This indicates that a resource used to be available, but is no longer available.

As with the ``[F]`` flag, you will typically use the "-" syntax for the rewrite target when using the ``[G]`` flag:

::

    RewriteRule oldproduct - [G,NC]

When using ``[G]``, an ``[L]`` is implied - that is, the response is returned immediately, and no further rules are evaluated.

H - handler
'''''''''''

.. index:: H flag
.. index:: Rewrite flags!H
.. index:: Flags!H

Forces the resulting request to be handled with the specified handler. For example, one might use this to force all files without a file extension to be parsed by the php handler:

::

    RewriteRule !\. - [H=application/x-httpd-php]

The regular expression above - ``!\.`` - will match any request that does not contain the literal . character.

This can be also used to force the handler based on some conditions. For example, the following snippet used in per-server context allows .php files to be displayed by mod\_php if they are requested with the .phps extension:

::

    RewriteRule ^(/source/.+\.php)s$ $1 [H=application/x-httpd-php-source]

The regular expression above - ``^(/source/.+\.php)s$`` - will match any request that starts with ``/source/`` followed by 1 or n characters followed by ``.phps`` literally. The backreference ``$1`` referrers to the captured match within parenthesis of the regular expression.

L - last
''''''''

.. index:: L flag
.. index:: Rewrite flags!L
.. index:: Flags!L

The ``[L]`` flag causes mod_rewrite to stop processing the rule set. In most contexts, this means that if the rule matches, no further rules will be processed. This corresponds to the last command in Perl, or the break command in C. Use this flag to indicate that the current rule should be applied immediately without considering further rules.

If you are using ``RewriteRule`` in either .htaccess files or in ``<Directory>`` sections, it is important to have some understanding of how the rules are processed. The simplified form of this is that once the rules have been processed, the rewritten request is handed back to the URL parsing engine to do what it may with it. It is possible that as the rewritten request is handled, the .htaccess file or ``<Directory>`` section may be encountered again, and thus the ruleset may be run again from the start. Most commonly this will happen if one of the rules causes a redirect - either internal or external - causing the request process to start over.

It is therefore important, if you are using ``RewriteRule`` directives in one of these contexts, that you take explicit steps to avoid rules looping, and not count solely on the ``[L]`` flag to terminate execution of a series of rules, as shown below.

An alternative flag, ``[END]``, can be used to terminate not only the current round of rewrite processing but prevent any subsequent rewrite processing from occurring in per-directory (htaccess) context. This does not apply to new requests resulting from external redirects.

The example given here will rewrite any request to index.php, giving the original request as a query string argument to ``index.php``, however, the ``RewriteCond`` ensures that if the request is already for index.php, the ``RewriteRule`` will be skipped.

::

    RewriteBase /
    RewriteCond %{REQUEST_URI} !=/index.php
    RewriteRule ^(.*) /index.php?req=$1 [L,PT]

See the :ref:`RewriteCond` chapter for further discussion of the `RewriteCond` directive.

N - next
''''''''

.. index:: N flag
.. index:: Rewrite flags!N
.. index:: Flags!N

The ``[N]`` flag causes the ruleset to start over again from the top, using the result of the ruleset so far as a starting point. Use with extreme caution, as it may result in loop.

The ``[N]`` flag could be used, for example, if you wished to replace a certain string or letter repeatedly in a request. The example shown here will replace A with B everywhere in a request, and will continue doing so until there are no more As to be replaced.

::

    RewriteRule (.*)A(.*) $1B$2 [N]

You can think of this as a while loop: While this pattern still matches (i.e., while the URI still contains an A), perform this substitution (i.e., replace the A with a B).

NC - nocase
'''''''''''

.. index:: NC flag
.. index:: Rewrite flags!NC
.. index:: Flags!NC

Use of the ``[NC]`` flag causes the ``RewriteRule`` to be matched in a case-insensitive manner. That is, it doesn't care whether letters appear as upper-case or lower-case in the matched URI.

In the example below, any request for an image file will be proxied to your dedicated image server. The match is case-insensitive, so that .jpg and .JPG files are both acceptable, for example.

::

    RewriteRule (.*\.(jpg|gif|png))$ http://images.example.com$1 [P,NC]

NE - noescape
'''''''''''''

.. index:: NE flag
.. index:: Rewrite flags!NE
.. index:: Flags!NE

By default, special characters, such as ``\&`` and ``?``, for example, will be converted to their hexcode equivalent. Using the ``[NE]`` flag prevents that from happening.

::

    RewriteRule ^/anchor/(.+) /bigpage.html#$1 [NE,R]

The above example will redirect ``/anchor/xyz`` to ``/bigpage.html#xyz``. Omitting the ``[NE]`` will result in the ``#`` being converted to its hexcode equivalent, ``%23``, which will then result in a 404 Not Found error condition.

NS - nosubreq
'''''''''''''

.. index:: NS flag
.. index:: Rewrite flags!NS
.. index:: Flags!NS

Use of the ``[NS]`` flag prevents the rule from being used on subrequests. For example, a page which is included using an SSI (Server Side Include) is a subrequest, and you may want to avoid rewrites happening on those subrequests. Also, when mod\_dir tries to find out information about possible directory default files (such as index.html files), this is an internal subrequest, and you often want to avoid rewrites on such subrequests. On subrequests, it is not always useful, and can even cause errors, if the complete set of rules are applied. Use this flag to exclude problematic rules.

To decide whether or not to use this rule: if you prefix URLs with CGI-scripts, to force them to be processed by the CGI-script, it's likely that you will run into problems (or significant overhead) on sub-requests. In these cases, use this flag.

Images, javascript files, or css files, loaded as part of an HTML page, are not subrequests - the browser requests them as separate HTTP requests.

P - proxy
'''''''''

.. index:: P flag
.. index:: Rewrite flags!P
.. index:: Flags!P

Use of the ``[P]`` flag causes the request to be handled by mod\_proxy, and handled via a proxy request. For example, if you wanted all image requests to be handled by a back-end image server, you might do something like the following:

::

    RewriteRule /(.*)\.(jpg|gif|png)$ http://images.example.com/$1.$2 [P]

Use of the ``[P]`` flag implies ``[L]``. That is, the request is immediately pushed through the proxy, and any following rules will not be considered.

You must make sure that the substitution string is a valid URI (typically starting with <http://hostname>) which can be handled by the mod\_proxy. If not, you will get an error from the proxy module. Use this flag to achieve a more powerful implementation of the ``ProxyPass`` directive, to map remote content into the namespace of the local server.

Security Warning
""""""""""""""""

Take care when constructing the target URL of the rule, considering the security impact from allowing the client influence over the set of URLs to which your server will act as a proxy. Ensure that the scheme and hostname part of the URL is either fixed, or does not allow the client undue influence.

Performance warning
"""""""""""""""""""

Using this flag triggers the use of mod\_proxy, without handling of persistent connections. This means the performance of your proxy will be better if you set it up with ``ProxyPass`` or ``ProxyPassMatch``.

This is because this flag triggers the use of the default worker, which does not handle connection pooling.
Avoid using this flag and prefer those directives, whenever you can.

Note: mod_proxy must be enabled in order to use this flag.

See Chapter \ref{chapter_proxy} for a more thorough treatment of proxying.

PT - passthrough
''''''''''''''''

.. index:: PT flag
.. index:: Rewrite flags!PT
.. index:: Flags!PT

The target (or substitution string) in a ``RewriteRule`` is assumed to be a file path, by default. The use of the ``[PT]`` flag causes it to be treated as a URI instead. That is to say, the use of the ``[PT]`` flag causes the result of the ``RewriteRule`` to be passed back through URL mapping, so that location-based mappings, such as ``Alias``, ``Redirect``, or ``ScriptAlias``, for example, might have a chance to take effect.

If, for example, you have an ``Alias`` for ``/icons``, and have a ``RewriteRule`` pointing there, you should use the ``[PT]`` flag to ensure that the ``Alias`` is evaluated.

::

    Alias /icons /usr/local/apache/icons
    RewriteRule /pics/(.+)\.jpg$ /icons/$1.gif [PT]

Omission of the ``[PT]`` flag in this case will cause the ``Alias`` to be ignored, resulting in a 'File not found' error being returned.

The ``[PT]`` flag implies the ``[L]`` flag: rewriting will be stopped in order to pass the request to the next phase of processing.

Note that the ``[PT]`` flag is implied in per-directory contexts such as ``<Directory>`` sections or in .htaccess files. The only way to circumvent that is to rewrite to -.

QSA - qsappend
''''''''''''''

.. index:: QSA flag
.. index:: Rewrite flags!QSA
.. index:: Flags!QSA

When the replacement URI contains a query string, the default behavior of RewriteRule is to discard the existing query string, and replace it with the newly generated one. Using the ``[QSA]`` flag causes the query strings to be combined.

Consider the following rule:

::

    RewriteRule /pages/(.+) /page.php?page=$1 [QSA]

With the ``[QSA]`` flag, a request for ``/pages/123?one=two`` will be mapped to ``/page.php?page=123&one=two``. Without the ``[QSA]`` flag, that same request will be mapped to ``/page.php?page=123`` - that is, the existing query string will be discarded.

QSD - qsdiscard
'''''''''''''''

.. index:: QSD flag
.. index:: Rewrite flags!QSD
.. index:: Flags!QSD

When the requested URI contains a query string, and the target URI does not, the default behavior of ``RewriteRule`` is to copy that query string to the target URI. Using the ``[QSD]`` flag causes the query string to be discarded.

This flag is available in version 2.4.0 and later.

Using ``[QSD]`` and ``[QSA]`` together will result in ``[QSD]`` taking precedence.

If the target URI has a query string, the default behavior will be observed - that is, the original query string will be discarded and replaced with the query string in the ``RewriteRule`` target URI.


R - redirect
''''''''''''

.. index:: R flag
.. index:: Rewrite flags!R
.. index:: Flags!R

Use of the ``[R]`` flag causes a HTTP redirect to be issued to the browser. If a fully-qualified URL is specified (that is, including <http://servername/>) then a redirect will be issued to that location. Otherwise, the current protocol, servername, and port number will be used to generate the URL sent with the redirect.

Any valid HTTP response status code may be specified, using the syntax ``[R=305]``, with a 302 status code being used by default if none is specified. The status code specified need not necessarily be a redirect (3xx) status code. However, if a status code is outside the redirect range (300-399) then the substitution string is dropped entirely, and rewriting is stopped as if the L were used.

In addition to response status codes, you may also specify redirect status using their symbolic names: temp (default), permanent, or seeother.

You will almost always want to use ``[R]`` in conjunction with ``[L]`` (that is, use ``[R,L]``) because on its own, the ``[R]`` flag prepends <http://thishost[:thisport]> to the URI, but then passes this on to the next rule in the ruleset, which can often result in 'Invalid URI in request' warnings.

S - skip
''''''''

.. index:: S flag
.. index:: Rewrite flags!S
.. index:: Flags!S

The ``[S]`` flag is used to skip rules that you don't want to run. The syntax of the skip flag is ``[S=N]``, where N signifies the number of rules to skip (provided the RewriteRule and any preceding RewriteCond directives match). This can be thought of as a goto statement in your rewrite ruleset. In the following example, we only want to run the RewriteRule if the requested URI doesn't correspond with an actual file.

::

    # Is the request for a non-existent file?
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d

    # If so, skip these two RewriteRules
    RewriteRule .? - [S=2]

    RewriteRule (.*\.gif) images.php?$1
    RewriteRule (.*\.html) docs.php?$1

This technique is useful because a ``RewriteCond`` only applies to the ``RewriteRule`` immediately following it. Thus, if you want to make a ``RewriteCond`` apply to several ``RewriteRule``s, one possible technique is to negate those conditions and add a ``RewriteRule`` with a ``[Skip]`` flag. You can use this to make pseudo if-then-else constructs: The last rule of the then-clause becomes skip=N, where N is the number of rules in the else-clause:

::

    # Does the file exist?
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d

    # Create an if-then-else construct by skipping 3 lines if we meant to go to the "else" stanza.
    RewriteRule .? - [S=3]

    # IF the file exists, then:
        RewriteRule (.*\.gif) images.php?$1
        RewriteRule (.*\.html) docs.php?$1
        # Skip past the "else" stanza.
        RewriteRule .? - [S=1]
    # ELSE...
        RewriteRule (.*) 404.php?file=$1
    # END


It is probably easier to accomplish this kind of configuration using the ``<If>``, ``<ElseIf>``, and ``<Else>`` directives instead. (2.4 and later -  See \ref{if}.)

T - type
''''''''

.. index:: T flag
.. index:: Rewrite flags!T
.. index:: Flags!T

Sets the MIME type with which the resulting response will be sent. This has the same effect as the ``AddType`` directive.

For example, you might use the following technique to serve Perl source code as plain text, if requested in a particular way:

::

    # Serve .pl files as plain text
    RewriteRule \.pl$ - [T=text/plain]

Or, perhaps, if you have a camera that produces jpeg images without file extensions, you could force those images to be served with the correct MIME type by virtue of their file names:

::

    # Files with 'IMG' in the name are jpg images.
    RewriteRule IMG - [T=image/jpg]

Please note that this is a trivial example, and could be better done using ``<FilesMatch>`` instead. Always consider the alternate solutions to a problem before resorting to rewrite, which will invariably be a less efficient solution than the alternatives.

If used in per-directory context, use only - (dash) as the substitution for the entire round of mod_rewrite processing, otherwise the MIME-type set with this flag is lost due to an internal re-processing (including subsequent rounds of mod_rewrite processing). The L flag can be useful in this context to end the current round of mod_rewrite processing.

.. index:: RewriteBase
.. _RewriteBase:

RewriteBase
-----------

.. todo:: RewriteBase chapter

.. index:: RewriteCond
.. _RewriteCond:

RewriteCond
-----------

The ``RewriteCond`` directive attaches additional conditions on a ``RewriteRule``, and may also set backreferences that may be used in the rewrite target.

One or more ``RewriteCond`` directives may precede a ``RewriteRule``
directive. That ``RewriteRule`` is then applied only if the current
state of the URI matches its pattern, and all of these conditions are
met.

The ``RewriteCond`` directive has the following syntax:

::

    RewriteCond TestString  CondPattern [Flag]

The arguments have the following meaning:

TestString
    Any string or variable to be tested for a match.

CondPattern
    A regular expression or other other expression to be compared
    against the TestString.

Flag
    One or more flags which modify the behavior of the condition.

These definitions will be expanded in the sections below.

TestString
``````````

TestString is a string which can contain the following expanded constructs in addition to plain text:

RewriteRule backreferences
    These are backreferences of the form `$N` (0 <= N <= 9). `$1` to `$9` provide access to the grouped parts (in parentheses) of the pattern, from the RewriteRule which is subject to the current set of RewriteCond conditions. $0 provides access to the whole string matched by that pattern.

RewriteCond backreferences
    These are backreferences of the form %N (0 <= N <= 9). %1 to %9 provide access to the grouped parts (again, in parentheses) of the pattern, from the last matched RewriteCond in the current set of conditions. %0 provides access to the whole string matched by that pattern.

RewriteMap expansions
    These are expansions of the form ${mapname:key|default}. See the documentation for RewriteMap for more details.

Server-Variables
    These are variables of the form %{ NAME_OF_VARIABLE } where NAME_OF_VARIABLE can be a string taken from the following list:

HTTP headers:

HTTP_USER_AGENT
HTTP_REFERER
HTTP_COOKIE
HTTP_FORWARDED
HTTP_HOST
HTTP_PROXY_CONNECTION
HTTP_ACCEPT


connection & request:   

REMOTE_ADDR
REMOTE_HOST
REMOTE_PORT
REMOTE_USER
REMOTE_IDENT
REQUEST_METHOD
SCRIPT_FILENAME
PATH_INFO
QUERY_STRING
AUTH_TYPE

server internals:

DOCUMENT_ROOT
SERVER_ADMIN
SERVER_NAME
SERVER_ADDR
SERVER_PORT
SERVER_PROTOCOL
SERVER_SOFTWARE


date and time:

TIME_YEAR
TIME_MON
TIME_DAY
TIME_HOUR
TIME_MIN
TIME_SEC
TIME_WDAY
TIME

specials:

API_VERSION
THE_REQUEST
REQUEST_URI
REQUEST_FILENAME
IS_SUBREQ
HTTPS
REQUEST_SCHEME

These variables all correspond to the similarly named HTTP MIME-headers, C variables of the Apache HTTP Server or struct tm fields of the Unix system. Most are documented elsewhere in the Manual or in the CGI specification.

SERVER_NAME and SERVER_PORT depend on the values of UseCanonicalName and UseCanonicalPhysicalPort respectively.

Those that are special to mod_rewrite include those below.

IS_SUBREQ
    Will contain the text "true" if the request currently being processed is a sub-request, "false" otherwise. Sub-requests may be generated by modules that need to resolve additional files or URIs in order to complete their tasks.

API_VERSION
    This is the version of the Apache httpd module API (the internal interface between server and module) in the current httpd build, as defined in include/ap_mmn.h. The module API version corresponds to the version of Apache httpd in use (in the release version of Apache httpd 1.3.14, for instance, it is 19990320:10), but is mainly of interest to module authors.

THE_REQUEST
    The full HTTP request line sent by the browser to the server (e.g., "GET /index.html HTTP/1.1"). This does not include any additional headers sent by the browser. This value has not been unescaped (decoded), unlike most other variables below.

REQUEST_URI
    The path component of the requested URI, such as "/index.html". This notably excludes the query string which is available as as its own variable named QUERY_STRING.

REQUEST_FILENAME
    The full local filesystem path to the file or script matching the request, if this has already been determined by the server at the time REQUEST_FILENAME is referenced. Otherwise, such as when used in virtual host context, the same value as REQUEST_URI. Depending on the value of AcceptPathInfo, the server may have only used some leading components of the REQUEST_URI to map the request to a file.

HTTPS
    Will contain the text "on" if the connection is using SSL/TLS, or "off" otherwise. (This variable can be safely used regardless of whether or not mod_ssl is loaded).

REQUEST_SCHEME
    Will contain the scheme of the request (usually "http" or "https"). This value can be influenced with ServerName.

If the TestString has the special value `expr`, the CondPattern will be treated as an `ap_expr`. HTTP headers referenced in the expression will be added to the Vary header if the `novary` flag is not given.

Other things you should be aware of:

The variables SCRIPT_FILENAME and REQUEST_FILENAME contain the same value - the value of the filename field of the internal request_rec structure of the Apache HTTP Server. The first name is the commonly known CGI variable name while the second is the appropriate counterpart of REQUEST_URI (which contains the value of the uri field of request_rec).

If a substitution occurred and the rewriting continues, the value of both variables will be updated accordingly.

If used in per-server context (i.e., before the request is mapped to the filesystem) SCRIPT_FILENAME and REQUEST_FILENAME cannot contain the full local filesystem path since the path is unknown at this stage of processing. Both variables will initially contain the value of REQUEST_URI in that case. In order to obtain the full local filesystem path of the request in per-server context, use an URL-based look-ahead %{LA-U:REQUEST_FILENAME} to determine the final value of REQUEST_FILENAME.

%{ENV:variable}, where variable can be any environment variable, is also available. This is looked-up via internal Apache httpd structures and (if not found there) via getenv() from the Apache httpd server process.

%{SSL:variable}, where variable is the name of an SSL environment variable, can be used whether or not mod_ssl is loaded, but will always expand to the empty string if it is not. Example: %{SSL:SSL_CIPHER_USEKEYSIZE} may expand to 128.

%{HTTP:header}, where header can be any HTTP MIME-header name, can always be used to obtain the value of a header sent in the HTTP request. Example: %{HTTP:Proxy-Connection} is the value of the HTTP header `Proxy-Connection:`.

If a HTTP header is used in a condition this header is added to the Vary header of the response in case the condition evaluates to to true for the request. It is not added if the condition evaluates to false for the request. Adding the HTTP header to the Vary header of the response is needed for proper caching.

It has to be kept in mind that conditions follow a short circuit logic in the case of the 'ornext|OR' flag so that certain conditions might not be evaluated at all.

%{LA-U:variable} can be used for look-aheads which perform an internal (URL-based) sub-request to determine the final value of variable. This can be used to access variable for rewriting which is not available at the current stage, but will be set in a later phase.

For instance, to rewrite according to the REMOTE_USER variable from within the per-server context (httpd.conf file) you must use %{LA-U:REMOTE_USER} - this variable is set by the authorization phases, which come after the URL translation phase (during which mod_rewrite operates).

On the other hand, because mod_rewrite implements its per-directory context (.htaccess file) via the Fixup phase of the API and because the authorization phases come before this phase, you just can use %{REMOTE_USER} in that context.

%{LA-F:variable} can be used to perform an internal (filename-based) sub-request, to determine the final value of variable. Most of the time, this is the same as LA-U above.

CondPattern
```````````

CondPattern is the condition pattern, a regular expression which is applied to the current instance of the TestString. TestString is first evaluated, before being matched against CondPattern.

CondPattern is usually a perl compatible regular expression, but there is additional syntax available to perform other useful tests against the Teststring:

You can prefix the pattern string with a '!' character (exclamation mark) to specify a non-matching pattern.

You can perform lexicographical string comparisons:

'<CondPattern' (lexicographically precedes)
    Treats the CondPattern as a plain string and compares it lexicographically to TestString. True if TestString lexicographically precedes CondPattern.

'>CondPattern' (lexicographically follows)
    Treats the CondPattern as a plain string and compares it lexicographically to TestString. True if TestString lexicographically follows CondPattern.

'=CondPattern' (lexicographically equal)
    Treats the CondPattern as a plain string and compares it lexicographically to TestString. True if TestString is lexicographically equal to CondPattern (the two strings are exactly equal, character for character). If CondPattern is "" (two quotation marks) this compares TestString to the empty string.

'<=CondPattern' (lexicographically less than or equal to)
    Treats the CondPattern as a plain string and compares it lexicographically to TestString. True if TestString lexicographically precedes CondPattern, or is equal to CondPattern (the two strings are equal, character for character).

'>=CondPattern' (lexicographically greater than or equal to)
    Treats the CondPattern as a plain string and compares it lexicographically to TestString. True if TestString lexicographically follows CondPattern, or is equal to CondPattern (the two strings are equal, character for character).

You can perform integer comparisons:

'-eq' (is numerically equal to)
    The TestString is treated as an integer, and is numerically compared to the CondPattern. True if the two are numerically equal.

'-ge' (is numerically greater than or equal to)
    The TestString is treated as an integer, and is numerically compared to the CondPattern. True if the TestString is numerically greater than or equal to the CondPattern.

'-gt' (is numerically greater than)
    The TestString is treated as an integer, and is numerically compared to the CondPattern. True if the TestString is numerically greater than the CondPattern.

'-le' (is numerically less than or equal to)
    The TestString is treated as an integer, and is numerically compared to the CondPattern. True if the TestString is numerically less than or equal to the CondPattern. Avoid confusion with the -l by using the -L or -h variant.

'-lt' (is numerically less than)
    The TestString is treated as an integer, and is numerically compared to the CondPattern. True if the TestString is numerically less than the CondPattern. Avoid confusion with the -l by using the -L or -h variant.

You can perform various file attribute tests:

'-d' (is directory)
    Treats the TestString as a pathname and tests whether or not it exists, and is a directory.

'-f' (is regular file)
    Treats the TestString as a pathname and tests whether or not it exists, and is a regular file.

'-F' (is existing file, via subrequest)
    Checks whether or not TestString is a valid file, accessible via all the server's currently-configured access controls for that path. This uses an internal subrequest to do the check, so use it with care - it can impact your server's performance!

'-H' (is symbolic link, bash convention)
    See -l.

'-l' (is symbolic link)
    Treats the TestString as a pathname and tests whether or not it exists, and is a symbolic link. May also use the bash convention of -L or -h if there's a possibility of confusion such as when using the -lt or -le tests.

'-L' (is symbolic link, bash convention)
    See -l.

'-s' (is regular file, with size)
    Treats the TestString as a pathname and tests whether or not it exists, and is a regular file with size greater than zero.

'-U' (is existing URL, via subrequest)
    Checks whether or not TestString is a valid URL, accessible via all the server's currently-configured access controls for that path. This uses an internal subrequest to do the check, so use it with care - it can impact your server's performance!

'-x' (has executable permissions)
    Treats the TestString as a pathname and tests whether or not it exists, and has executable permissions. These permissions are determined according to the underlying OS.

Note:

All of these tests can also be prefixed by an exclamation mark ('!') to negate their meaning.

If the TestString has the special value `expr`, the CondPattern will be treated as an ap_expr.

In the below example, -strmatch is used to compare the REFERER against the site hostname, to block unwanted hotlinking.

::

    RewriteCond expr "! %{HTTP_REFERER} -strmatch '*://%{HTTP_HOST}/*'"
    RewriteRule ^/images - [F]

Flag
````

You can also set special flags for CondPattern by appending [flags] as the third argument to the RewriteCond directive, where flags is a comma-separated list of any of the following flags:

'nocase|NC' (no case)
    This makes the test case-insensitive - differences between 'A-Z' and 'a-z' are ignored, both in the expanded TestString and the CondPattern. This flag is effective only for comparisons between TestString and CondPattern. It has no effect on filesystem and subrequest checks.

'ornext|OR' (or next condition)
    Use this to combine rule conditions with a local OR instead of the implicit AND. Typical example:

::

    RewriteCond %{REMOTE_HOST}  ^host1  [OR]
    RewriteCond %{REMOTE_HOST}  ^host2  [OR]
    RewriteCond %{REMOTE_HOST}  ^host3
    RewriteRule ...some special stuff for any of these hosts... 

Without this flag you would have to write the condition/rule pair three times.

'novary|NV' (no vary)
    If a HTTP header is used in the condition, this flag prevents this header from being added to the Vary header of the response. 

Using this flag might break proper caching of the response if the representation of this response varies on the value of this header. So this flag should be only used if the meaning of the Vary header is well understood.

Examples
````````

.. todo::

Query Strings
.. index:: rewritemap_int
'''''''''''''

.. todo::

Files and Directories
'''''''''''''''''''''

.. todo::

.. index:: RewriteMap
.. _RewriteMap:

RewriteMap
----------

The ``RewriteMap`` directive gives you a way to call external mapping routines to simplify a ``RewriteRule``. This external mapping can be a flat text file containing one-to-one mappings, or a database, or a script that produces mapping rules, or a variety of other similar things. In this chapter we'll discuss how to use a ``RewriteMap`` in a ``RewriteRule`` or ``RewriteCond``.

Creating a RewriteMap
`````````````````````

The ``RewriteMap`` directive creates an alias which you can then invoke in either a ``RewriteRule`` or ``RewriteCond`` directive. You can think of it as defining a function that you can call later on.

The syntax of the ``RewriteMap`` directive is as follows:

::

    RewriteMap MapName MapType:MapSource

Where the various parts of that syntax are defined as:

MapName
    The name of the 'function' that you're creating

MapType
    The type of the map. The various available map types are discussed below.

MapSource
    The location from which the map definition will be obtained, such as a file, database query, or predefined function.

The ``RewriteMap`` directive must be used either in virtualhost context, or in global server context. This is because a ``RewriteMap`` is loaded at server startup time, rather than at request time, and, as such, cannot be specified in a ``.htaccess`` file.

.. todo:: Example

Using a RewriteMap
``````````````````

Once you have defined a ``RewriteMap``, you can then use it in a ``RewriteRule`` or ``RewriteCond`` as follows:

::

    RewriteMap examplemap txt:/path/to/file/map.txt
    RewriteRule ^/ex/(.*) ${examplemap:$1}

Note in this example that the ``RewriteMap``, named 'examplemap', is passed an argument, ``$1``, which is captured by the ``RewriteRule`` pattern. It can also be passed an argument of another known variable. For example, if you wanted to invoke the ``examplemap`` map on the entire requested URI, you could use the variable ``%{REQUEST_URI}`` rather than ``$1`` in your invocation:

::

    RewriteRule ^ ${examplemap:%{REQUEST_URI}}

.. todo:: DEFAULT RESULT

RewriteMap Types
````````````````

There are a number of different map types which may be used in a ``RewriteMap``.

int
'''

.. index:: RewriteMap!int
.. index:: rewritemap_int

An ``int`` map type is an internal function, pre-defined by ``mod_rewrite`` itself. There are four such functions:

toupper
"""""""

The ``toupper`` internal function converts the provided argument text to all upper case characters.

::

    # Convert any lower-case request to upper case and redirect
    RewriteMap uc int:toupper
    RewriteRule (.*?[a-z]+.*) ${uc:$1} [R=301]

tolower
"""""""

The ``tolower`` is the opposite of ``toupper``, converting any argument text to lower case characters.

::

    # Convert any upper-case request to lower case and redirect
    RewriteMap lc int:tolower
    RewriteRule (.*?[A-Z]+.*) ${lc:$1} [R=301]

escape
""""""

unescape
""""""""

txt
'''

.. index:: RewriteMap!txt

A ``txt`` map defines a one-to-one mapping from argument to target.

rnd
'''

.. index:: RewriteMap!rnd

A ``rnd`` map will randomly select one value from the specified text file.

dbm
'''

.. index:: RewriteMap!dbm

prg
'''

.. index:: RewriteMap!prg

dbd
'''

.. index:: RewriteMap!dbd

.. _Proxying with mod_rewrite:

Proxying with mod_rewrite
-------------------------

mod_rewrite logging and debugging
---------------------------------

.. index:: Logging
.. _RewriteLogging:

Logging
```````

Exactly how you turn on logging for mod_rewrite will depend on what version of the Apache http server you are running. Logging got some updates in the 2.4 release of the server, and the rewrite log was one of the changes that happened at that time.

If you're not sure what version you're running, you can get the ``httpd`` binary to tell you with the ``-v`` flag:

::

    httpd -v

As with any other logging, the log file is opened when the server is
started up, before the server relinquishes its root privileges. For this
reason, the ``RewriteLog`` directive may not be used in ``.htaccess``
files, but may only be invoked in the server configuration file.

2.2 and earlier
'''''''''''''''

Prior to httpd 2.4, the way to enable mod_rewrite logging is with the
``RewriteLog`` and ``RewriteLogLevel`` directives.

The ``RewriteLog`` directive should be set to the location of your
rewrite log file, and the ``RewriteLogLevel`` is set to a value from 0
to 5 to indicate the desired verbosity of the log file, with 0 being no
log entries, and 5 being to log every time mod_rewrite even thinks about
doing something.

You'll often find advice online suggesting that ``RewriteLogLevel`` be
set to 9 for maximum verbosity. Numbers higher than 5 don't make it more
verbose, but they also don't harm anything.

::

    RewriteLog logs/rewrite.log
    RewriteLogLevel 5

2.4 and later
'''''''''''''

In the 2.4 version of the server, many changes were made to the way that
logging works. One of these changes was the addition of per-module log
configurations. This rendered the ``RewriteLog`` directive superfluous.
So, from 2.4 on, rewrite logging is enabled using the ``LogLevel``
directive, specifying a ``trace`` log level for mod_rewrite.

::

    LogLevel info rewrite:trace6

Rewrite log entries will now show up in the main error log file, as
specified by the ``ErrorLog`` directive.

What's in the Rewrite log? - An example
'''''''''''''''''''''''''''''''''''''''
The best way to talk about what's in the rewrite log is to show you some
examples of the kinds of things that mod_rewrite logs.

Consider a simple rewrite scenario such as follows:

::

    RewriteEngine On
    RewriteCond %{REQUEST_URI} !index.php
    RewriteRule . /index.php [PT,L]

    LogLevel info rewrite:trace6

    # Or, in 2.2
    # RewriteLog Level 5
    # RewriteLog /var/log/httpd/rewrite.log

This ruleset says "If it's not already ``index.php``, rewrite it to
``index.php``.

Now, we'll make a request for the URL http://localhost/example and see
what gets logged:

::

    [Thu Sep 12 20:22:13.363463 2013] [rewrite:trace2] [pid 11879]
    mod_rewrite.c(468): [client 127.0.0.1:56623] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] init rewrite
    engine with requested uri /example

    [Thu Sep 12 20:22:13.363510 2013] [rewrite:trace3] [pid 11879]
    mod_rewrite.c(468): [client 127.0.0.1:56623] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] applying
    pattern '.' to uri '/example'

    [Thu Sep 12 20:22:13.363525 2013] [rewrite:trace4] [pid 11879]
    mod_rewrite.c(468): [client 127.0.0.1:56623] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] RewriteCond:
    input='/example' pattern='!index.php' => matched

    [Thu Sep 12 20:22:13.363533 2013] [rewrite:trace2] [pid 11879]
    mod_rewrite.c(468): [client 127.0.0.1:56623] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] rewrite
    '/example' -> 'index.php'

    [Thu Sep 12 20:22:13.363542 2013] [rewrite:trace2] [pid 11879]
    mod_rewrite.c(468): [client 127.0.0.1:56623] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] local path
    result: index.php

    [Thu Sep 12 20:22:13.575877 2013] [rewrite:trace2] [pid 11881]
    mod_rewrite.c(468): [client 127.0.0.1:56624] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] init rewrite
    engine with requested uri /favicon.ico

    [Thu Sep 12 20:22:13.575920 2013] [rewrite:trace3] [pid 11881]
    mod_rewrite.c(468): [client 127.0.0.1:56624] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] applying
    pattern '.' to uri '/favicon.ico'

    [Thu Sep 12 20:22:13.575935 2013] [rewrite:trace4] [pid 11881]
    mod_rewrite.c(468): [client 127.0.0.1:56624] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] RewriteCond:
    input='/favicon.ico' pattern='!index.php' => matched

    [Thu Sep 12 20:22:13.575943 2013] [rewrite:trace2] [pid 11881]
    mod_rewrite.c(468): [client 127.0.0.1:56624] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] rewrite
    '/favicon.ico' -> 'index.php'

    [Thu Sep 12 20:22:13.575955 2013] [rewrite:trace2] [pid 11881]
    mod_rewrite.c(468): [client 127.0.0.1:56624] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] local path
    result: index.php

This is an entry from a 2.4 server, and contains a few elements that
will be missing from rewrite log entries for 2.2 and earlier. [#]_

Note that I've inserted linebreaks between each log entry for
legibility. And speaking of legibility, let's consider one single log
entry to see what the various components mean before we go any further.

Let's look at the first log entry.

::


    [Thu Sep 12 20:22:13.363463 2013] [rewrite:trace2] [pid 11879]
    mod_rewrite.c(468): [client 127.0.0.1:56623] 127.0.0.1 - -
    [localhost/sid#7f985f445348][rid#7f985f949040/initial] init rewrite
    engine with requested uri /example

That's a lot to process all at once, so we'll break it down one field at
a time.

``[Thu Sep 12 20:22:13.363463 2013]``
    The date and time when the event occurred.

``[rewrite:trace2]``
    The name of the module logging, and the loglevel at which it is
    logging. This is 2.4-specific

``[pid 1879]``
    The process id of the httpd process handling this request. This will
    be the same across a given request. Note that in this example there
    are two separate requests being handled, as you'll see in a moment.

``mod_rewrite.c(468):``
    For in-depth debugging, this is the line number in the module source
    code which is handling the current rewrite.

``[client 127.0.0.1:56623]``
    The client IP address, and TCP port number on which the request
    connection was made.

``-``
    This field contains the client's username in the event that the
    request was authenticated. In this example the request was `not`
    authenticated, so a blank value is logged.

``-``
    In the event that the request sent ident information, this will be
    logged here. This hardly ever happens, and so this field will almost
    always be ``-``.

``[localhost/sid#7f985f445348][rid#7f985f949040/initial]``
    This is the unique identifier for the request.

``init rewrite engine with requested uri /example``
    Ahah! Finally! The actual log message from mod_rewrite!

Now that you know what all of the various fields are in the log entry,
let's just look at the ones we actually care about. Here's the log file
again, with a lot of the superfluous information removed:

::

    init rewrite engine with requested uri /example
    applying pattern '.' to uri '/example'
    RewriteCond: input='/example' pattern='!index.php' => matched
    rewrite '/example' -> 'index.php'
    local path result: index.php

    init rewrite engine with requested uri /favicon.ico
    applying pattern '.' to uri '/favicon.ico'
    RewriteCond: input='/favicon.ico' pattern='!index.php' => matched
    rewrite '/favicon.ico' -> 'index.php'
    local path result: index.php

I've removed the extraneous information, and split the log entries into
two logical chunks. 

In the first bit, the requested URL ``/example`` is
run through the ruleset and ends up getting rewritten to ``/index.php``,
as desired.

In the second bit, the browser requests the URL ``/favicon.ico`` as a
side effect of the initial request. ``favicon`` is the icon that appears
in your browser address bar next to the URL, and is an automatic feature
of most browsers. As such, you're likely to see mention of
``favicon.ico`` in your log files from time to time, and it's nothing to
worry too much about. You can read more about favicons at
<http://en.wikipedia.org/wiki/Favicon>.

Follow through the log lines for the first of the two requests.

First, the rewrite engine is made aware that it needs to consider a URL,
and the ``init rewrite engine`` log entry is made.

Next, the ``RewriteRule`` pattern ``.`` is applied to the requested
URI ``/example``, and this comparison is logged. In
your configuration file, the ``RewriteRule`` appears `after` the
``RewriteCond``, but at request time, the ``RewriteRule`` pattern is
applied `first`.

Since the pattern does match, in this case, we continue to the
``RewriteCond``, and the pattern ``!index.php`` is applied to the string
``/example``. Both the pattern and the string it is being applied to are
logged, which can be very useful later on in debugging rules that aren't
behaving quite as you intended. This log line also tells you that the
pattern ``matched``.

Since the ``RewriteRule`` pattern and the ``RewriteCond`` both matched,
we continue on to the right hand side of the ``RewriteRule`` and apply
the rewrite, and ``/example`` is rewritten to ``index.php``, which is
also logged. A final log entry tells us what the local path result ends
up being after this process, which is ``index.php``.

This kind of detailed log trail tells you very specifically what's going
on, and what happened at each step. [#]_

RewriteRules in .htaccess files - An example
''''''''''''''''''''''''''''''''''''''''''''

We've previously discussed using mod_rewrite in .htaccess files, but
it's time to see what this actually looks like in practice. Let's
replace the configuration file entry above with a .htaccess file
instead, placed in the root document directory of our website. So, I'm
going to comment out several lines in the server configuration:

::

    # RewriteEngine On
    # RewriteCond %{REQUEST_URI} !index.php
    # RewriteRule . /index.php [PT,L]

    LogLevel info rewrite:trace6

    # Or, in 2.2
    # RewriteLog Level 5
    # RewriteLog /var/log/httpd/rewrite.log

And instead, I'm going to place the following .htaccess file:

::

    RewriteEngine On
    RewriteCond %{REQUEST_URI} !index.php                                     
    RewriteRule . /index.php [PT,L]

Now, see what the log file looks like:

For the sake of brevity, let's look at just the actual log messages, and
ignore all of the extra information:

::

    [perdir /var/www/html/] strip per-dir prefix: /var/www/html/example -> example
    [perdir /var/www/html/] applying pattern '.' to uri 'example'
    [perdir /var/www/html/] input='/example' pattern='!index.php' => matched
    [perdir /var/www/html/] rewrite 'example' -> '/index.php'
    [perdir /var/www/html/] forcing '/index.php' to get passed through to next API URI-to-filename handler
    [perdir /var/www/html/] internal redirect with /index.php [INTERNAL REDIRECT]
    [perdir /var/www/html/] strip per-dir prefix: /var/www/html/index.php -> index.php
    [perdir /var/www/html/] applying pattern '.' to uri 'index.php'
    [perdir /var/www/html/] RewriteCond: input='/index.php' pattern='!index.php' => not-matched
    [perdir /var/www/html/] pass through /var/www/html/index.php

The first thing you'll notice, of course, is that this is much longer
than what we had before. Running rewrite rules in .htaccess files
generally takes several more steps than when the rules are in the server
configuration file, which is one of several reasons that using .htaccess
files is so much less efficient (i.e., slower) than using the server
configuration file.

Whenever possible, you should use the server configuration file rather
than .htaccess files. (There are other reasons for this, too.)

Next, you'll notice that each log entry contains the preface:

::
    
    [perdir /var/www/html]

``perdir`` refers to rewrite directives that occur in `per directory`
context - i.e., .htaccess files or ``<Directory>`` blocks. They are
treated special in a few different ways, as we'll see.

The first of these is shown in the first log entry:

::

    strip per-dir prefix: /var/www/html/example -> example

What that means is that in `perdir` context, the directory path is
removed from any string before they are considered in the pattern match.
Thus, rather than considering the string ``/example``, as we did the
first time through, now we're looking at the string ``example``. While
this may seem trivial at this point, as we proceed to more complex
examples, that leading slash will be the difference between a pattern
matching and not matching, so you need to be aware of this every time
you use ``.htaccess`` files.

The next few lines of the log proceed as before, except that we're
looking at ``example`` rather than ``/example`` in each line. Carefully
compare the log entries from the first time through to the ones this
time.

What happens next is a surprise to most first-time users of mod_rewrite.
The requested URI ``example`` is redirected to the URI ``/index.php``,
and the whole process starts over again with that new URL. This is
because, in `perdir` context, once a rewrite has been executed, that
target URL must get passed back to the URL mapping process to
determine what that URL maps to ... which may include invoking a
.htaccess file.

In this case, this causes the ruleset to be executed all over again,
with the rewritten URL ``/index.php``.

The remainder of the log should look very familiar. It's the same as
what we saw before, with ``/index.php`` getting stripped to
``index.php`` and run through the paces. This time around, however, the
``RewriteCond`` does not match, and so the request is passed through
unchanged.

Rewrite Examples
----------------

TODO

This section will present a cookbook of common examples of how you'll use mod_rewrite in the real world. Each example is presented as a problem statement, a solution, and then a discussion of the solution and possible alternatives.

This chapter is likely to evolve over time, and so you are encouraged to check back at <http://mod-rewrite.org/> frequently for updates.

.. [#] Or, more to the point, it prevents malicious end-users from finding ways to look there.

.. [#] Future editions of this book will contain full examples from a 2.2 server, for those still running that version.

.. [#] Future editions of this bill will contain an appendix in which several log traces are explained in exhaustive detail. I can hardly wait.

