require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Foo < ActiveFedora::Base
      has_metadata "foostream", type: ActiveFedora::SimpleDatastream do |m|
        m.field "foostream", :string
      end
      has_metadata 'dcstream', type: ActiveFedora::QualifiedDublinCoreDatastream
    end
    class Bar  < ActiveFedora::Base
      has_metadata 'barstream', type: ActiveFedora::SimpleDatastream do |m|
        m.field "barfield", :string
      end
    end
  end

  it "doesn't overwrite stream specs" do
    f = Foo.new
    f.datastreams.size.should == 2
    streams = f.datastreams.values.map{|x| x.class.to_s}.sort
    streams.pop.should == "ActiveFedora::SimpleDatastream"
    streams.pop.should == "ActiveFedora::QualifiedDublinCoreDatastream"
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
  
