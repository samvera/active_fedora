Description
-----------

[![Build Status](https://travis-ci.org/projecthydra/active_fedora.png?branch=master)](https://travis-ci.org/projecthydra/active\_fedora)
[![Version](https://badge.fury.io/rb/active-fedora.png)](http://badge.fury.io/rb/active-fedora)
[![Dependencies](https://gemnasium.com/projecthydra/active_fedora.png)](https://gemnasium.com/projecthydra/active\_fedora)

RubyFedora and ActiveFedora provide a set of Ruby gems for creating and
managing objects in the Fedora Repository Architecture
([http://fedora-commons.org](http://fedora-commons.org)). ActiveFedora
is loosely based on “ActiveRecord” in Rails. The 3.x series of
ActiveFedora depends on Rails 3, specifically activemodel and
activesupport.

Getting Help
------------

-   Community Discussions & Mailing List are located at
    [http://groups.google.com/group/hydra-tech](http://groups.google.com/group/hydra-tech)
-   Developers hang out on IRC in \#projecthydra on freenet.

Installation
------------

The gem is hosted on gemcutter.

    gem install active-fedora

Getting Started
---------------

The [ActiveFedora Console
Tour](https://github.com/projecthydra/active_fedora/wiki/Getting-Started:-Console-Tour)
gives you a brief tour through ActiveFedora’s features on the command
line.

Generators
----------

You can generate a model inheriting from ActiveFedora::Base.

    rails generate active_fedora:model Book

Testing (this Gem)
------------------

In order to run the RSpec tests, you need to have a copy of the
ActiveFedora source code, and then run bundle install in the source
directory. Testing requires hydra-jetty, which contains version for
Fedora and Solr. Setting up and maintaining hydra-jetty for the purposes
of testing this gem is all accomplished via

    git clone https://github.com/projecthydra/active_fedora.git
    cd /wherever/active_fedora/is
    bundle install

### Using the continuous integration server

You can test ActiveFedora using the same process as our continuous
integration server. To do that, unzip a copy\
of hydra-jetty first. This includes copies of Fedora and Solr which are
used during the testing process.

      rake jetty:unzip 

Once hydra-jetty is unzipped, the ci rake task will spin up jetty,
import the fixtures, and run the tests for you.

      rake active_fedora:ci

### Testing Manually

If you want to run the tests manually, follow these instructions.

You need to have a copy of hydra-jetty running. To do this, download a
working copy of
[hydra-jetty](https://github.com/projecthydra/hydra-jetty), cd into its
root and run

    java -jar start.jar

Now you’re ready to run the tests. In the directory where active\_fedora
is installed, run

      rake spec

Predicate Mappings
------------------

ActiveFedora versions 2.2.1 and higher provides specialized control over
the predicate mappings used by SemanticNode. In order to provide your
own mappings, \
you must supply a predicate\_mappings.yml in the same format as the
config/predicate\_mappings.yml file shipped with the ActiveFedora gem.
Place the file in the same directory\
as your fedora.yml file and use the current method of initializing
ActiveFedora:

    ActiveFedora.init("/path/to/my/config/fedora.yml")

If no predicate\_mappings.yml file is found, ActiveFedora will use the
default mappings.

Acknowledgements
----------------

Creator: Matt Zumwalt ([MediaShelf](http://yourmediashelf.com))

Developers: \
Justin Coyne, McClain Looney & Eddie Shin
([MediaShelf](http://yourmediashelf.com)), Rick Johnson (Notre Dame)

LICENSE:
--------

Copyright © 2009-2012 Matt Zumwalt & MediaShelf, LLC

This program is free software: you can redistribute it and/or modify\
it under the terms of the GNU Lesser General Public License (LGPL) as \
published by the Free Software Foundation, either version 3 of the
License, \
or (at your option) any later version.

This program is distributed in the hope that it will be useful,\
but WITHOUT ANY WARRANTY; without even the implied warranty of\
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License\
along with this program. If not, see <http://www.gnu.org/licenses/> or \
see <http://www.gnu.org/licenses/lgpl.html>.

The above copyright notice and this permission notice shall be\
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND,\
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF\
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.\
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY\
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,\
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE\
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
