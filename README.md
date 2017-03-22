Description
-----------

[![Build Status](https://travis-ci.org/projecthydra/active_fedora.png?branch=master)](https://travis-ci.org/projecthydra/active\_fedora)
[![Version](https://badge.fury.io/rb/active-fedora.png)](http://badge.fury.io/rb/active-fedora)
[![Dependencies](https://gemnasium.com/projecthydra/active_fedora.png)](https://gemnasium.com/projecthydra/active\_fedora)
[![Coverage Status](https://img.shields.io/coveralls/projecthydra/active_fedora.svg)](https://coveralls.io/r/projecthydra/active_fedora)

ActiveFedora is a Ruby gem for creating and
managing objects in the Fedora Repository Architecture
([http://fedora-commons.org](http://fedora-commons.org)). ActiveFedora
is loosely based on “ActiveRecord” in Rails. Version 9.0+ works with Fedora 4 and prior versions work on Fedora 3. Version 9.2+ works with Solr 4.10. Version 10.0+ works with Fedora >= 4.5.1.

Getting Help
------------

-   Community Discussions & Mailing List are located at
    [http://groups.google.com/group/hydra-tech](http://groups.google.com/group/hydra-tech)
-   Developers hang out on IRC in \#projecthydra on freenet.

Installation
------------

The gem is hosted on rubygems.

```bash
gem install active-fedora
```

Getting Started
---------------

The [Dive into Hydra](https://github.com/projecthydra/hydra/wiki/Dive-into-Hydra)
gives you a brief tour through ActiveFedora’s features on the command line.

Generators
----------

You can generate a model inheriting from ActiveFedora::Base.

```bash
rails generate active_fedora:model Book
```

Testing (this Gem)
------------------

In order to run the RSpec tests, you need to have a copy of the
ActiveFedora source code, and then run bundle install in the source
directory. Testing requires hydra-jetty, which contains version for
Fedora and Solr. Setting up and maintaining hydra-jetty for the purposes
of testing this gem is all accomplished via:

```bash
git clone https://github.com/projecthydra/active_fedora.git
cd active_fedora   # or whatever directory your clone is in
bundle install
```

### Using the continuous integration server

You can test ActiveFedora using the same process as our continuous
integration server. To do that, unzip a copy of hydra-jetty first. This includes copies of Fedora and Solr which are
used during the testing process.

The `ci` rake task will download solr and fedora, start them,
and run the tests for you.

```bash
rake active_fedora:ci
```

### Testing Manually

If you want to run the tests manually, follow these instructions:

```bash
solr_wrapper
```

To start FCRepo, open another shell and run:

```bash
fcrepo_wrapper -p 8986
```

Now you’re ready to run the tests. In the directory where active\_fedora
is installed, run:

```bash
rake spec
```

Acknowledgements
----------------

Creator: Matt Zumwalt ([MediaShelf](http://yourmediashelf.com))

Developers:
Justin Coyne, McClain Looney & Eddie Shin
([MediaShelf](http://yourmediashelf.com)), Rick Johnson (Notre Dame)
