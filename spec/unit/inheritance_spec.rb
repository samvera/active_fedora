require File.join( File.dirname(__FILE__), "../spec_helper" )

require 'active_fedora'
require 'active_fedora/base'
require 'active_fedora/metadata_datastream'
require 'active_fedora/qualified_dublin_core_datastream'

describe ActiveFedora::Base do
  before(:each) do
    Fedora::Repository.instance.stubs(:nextid).returns("_nextid_")
    class Foo < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"foostream" do|m|
        m.field "foostream", :string
      end
      has_metadata :type=>ActiveFedora::QualifiedDublinCoreDatastream, :name=>"dcstream" do|m|
        m.field "fz", :string
      end
    end
    class Bar  < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"barstream" do |m|
        m.field "barfield", :string
      end
    end
  end

  it "doesn't overwrite stream specs" do
    f = Foo.new
    f.datastreams.size.should == 2 #doesn't get dc until saved
    streams = f.datastreams.values.map(&:class).sort
#    streams.pop.name.should == "ActiveFedora::Datastream" #dc isn't here till saved
    streams.pop.name.should == "ActiveFedora::MetadataDatastream"
    streams.pop.name.should == "ActiveFedora::QualifiedDublinCoreDatastream"
  end

  it "should work for multiple types" do
    b = Foo.new
    f = Bar.new
    b.class.ds_specs.should_not == f.class.ds_specs
  end
  after do
    Object.send(:remove_const, :Bar)
    Object.send(:remove_const, :Foo)
  end

end
  
