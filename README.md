Description
-----------

[![Build Status](https://travis-ci.org/samvera/active_fedora.png?branch=master)](https://travis-ci.org/samvera/active\_fedora)
[![Version](https://badge.fury.io/rb/active-fedora.png)](http://badge.fury.io/rb/active-fedora)
[![Dependencies](https://gemnasium.com/samvera/active_fedora.png)](https://gemnasium.com/samvera/active\_fedora)
[![Coverage Status](https://img.shields.io/coveralls/samvera/active_fedora.svg)](https://coveralls.io/r/samvera/active_fedora)

ActiveFedora is a Ruby gem for creating and
managing objects in the Fedora Repository Architecture
([http://fedora-commons.org](http://fedora-commons.org)). ActiveFedora
is loosely based on “ActiveRecord” in Rails. Version 9.0+ works with Fedora 4 and prior versions work on Fedora 3. Version 9.2+ works with Solr 4.10. Version 10.0+ works with Fedora >= 4.5.1.

Getting Help
------------

-   Community Discussions & Mailing List are located at
    [http://groups.google.com/group/samvera-tech](http://groups.google.com/group/samvera-tech)
-   Developers hang out on [slack.samvera.org](http://slack.samvera.org/)

Installation
------------

The gem is hosted on rubygems.

```bash
gem install active-fedora
```

Getting Started
---------------

The [Dive into Hydra](https://github.com/samvera/hydra/wiki/Dive-into-Hydra)
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
directory. You can download the source code by doing the following:

```bash
git clone https://github.com/samvera/active_fedora.git
cd active_fedora
bundle install
```

### Using the continuous integration server

You can test ActiveFedora using the same process as our continuous
integration server. This will automatically pull down a copy of Solr and Fedora Content Repository.

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
