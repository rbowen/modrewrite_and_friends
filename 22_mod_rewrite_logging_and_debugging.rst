mod_rewrite logging and debugging
---------------------------------

.. _Logging:
.. index:: Logging

Logging
```````

Exactly how you turn on logging for mod\_rewrite will depend on what version of the Apache http server you are running. Logging got some updates in the 2.4 release of the server, and the rewrite log was one of the changes that happened at that time.

If you're not sure what version you're running, you can get the ``httpd`` binary to tell you with the ``-v`` flag:

::

    httpd -v

2.2 and earlier
'''''''''''''''

TODO: Discussion of why you can't use RewriteLog in .htaccess files

2.4 and later
'''''''''''''

TODO: Discussion of why you can't use rewrite logging in .htaccess files.

Debugging rewrite rules
```````````````````````

