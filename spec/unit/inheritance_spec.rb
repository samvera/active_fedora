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
    expect(f.attached_files.size).to eq 2
    streams = f.attached_files.values.map{|x| x.class.to_s}.sort
    expect(streams.pop).to eq "ActiveFedora::SimpleDatastream"
    expect(streams.pop).to eq "ActiveFedora::QualifiedDublinCoreDatastream"
  end

  it "should work for multiple types" do
    b = Foo.new
    f = Bar.new
    expect(b.class.ds_specs).to_not eq f.class.ds_specs
  end
  after do
    Object.send(:remove_const, :Bar)
    Object.send(:remove_const, :Foo)
  end

end
  
