Conditional Configuration
=========================

Introduction
------------

While the Apache httpd configuration files have always had some ways to make things conditional, with the advent of version 2.4, there's an explosion in the ways that you can make your configuration file reactive and programmable. That is, you can make your configuration more responsive to the specifics of the request that it servicing.

In this part of the book, we discuss some of this functionality. Some of it is specific to version 2.4 and later, while some of it has been available for years.

Define and IfDefine
-------------------

.. index:: Define
.. index:: IfDefine

<If>, <Elsif>, and <Else>
-------------------------

.. index:: If
.. index:: <If>

New in Apache httpd 2.4 is the ability to put `<If>` blocks in your configuration file to make it truly conditional. This provides a level of flexibility that was never before available.

In this chapter we'll show you how to use that feature, and give some examples of what you might do with it.

mod_macro
---------

.. index:: mod_macro

Conditional logging
-------------------

env=
````

Per-directory logging
`````````````````````

Piped logging
`````````````
