GraphFinder Wrapper for OKBQA
=============================

It is a wrapper WS to call the GraphFinder::spaqlator method from the OKBQA framework.
The project GraphFinder is at https://github.com/lodqa/graphfinder.

Prerequisite
-----
You need to install and deploy graphfinder, beforehand.

Interpreter
-----
ruby-2.1.2

Install
-----
(after cloning)
bundle install

Deploy
-----
rackup -p port_number -E production -D

Input
-----

* template: a template as generated by the template generation module of OKBQA
* disambiguation: a disambiguation as generated by the disambiguation module of OKBQA

Output
------

* Variation of SPARQL queries that represents the template and disambiguation

Author
------

* [Jin-Dong Kim](http://data.dbcls.jp/~jdkim/)

License
-------

Released under the [MIT license](http://opensource.org/licenses/MIT).
