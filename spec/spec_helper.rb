require 'rubygems'
gem 'mocha'
require 'ruby-debug'
require 'mocha'
require 'ruby-fedora'
begin
  require 'spec'
rescue LoadError
  gem 'rspec'
  require 'spec'
end

ENV["RAILS_ENV"] ||= 'test'
RAILS_ENV = ENV["RAILS_ENV"]

$:.unshift(File.dirname(__FILE__) + '/../lib')
Dir[File.join(File.dirname(__FILE__)+'/../lib/')+'**/*.rb'].each{|x| require x}
$VERBOSE=nil

# This loads the Fedora and Solr config info from /config/fedora.yml
# You can load it from a different location by passing a file path as an argument.
ActiveFedora.init(File.join(File.dirname(__FILE__), "..", "config", "fedora.yml"))

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

#TEST_FEDORA_URL = 'http://fedoraAdmin:fedoraAdmin@127.0.0.1:8080/fedora' 
#TEST_SOLR_URL = 'http://127.0.0.1:8080/solr' 
#Fedora::Repository.register(TEST_FEDORA_URL)
#ActiveFedora::SolrService.register(TEST_SOLR_URL)



def fixture(file)
  File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
end

def validate_xml(xml, expected_root)
  root = REXML::Document.new(xml).root
  root.should_not be_nil
  root.name.should == expected_root
end
