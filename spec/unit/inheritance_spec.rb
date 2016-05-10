require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class MyDS < ActiveFedora::OmDatastream
    end
    class Foo < ActiveFedora::Base
      has_subresource 'foostream', class_name: 'MyDS'
      has_subresource 'dcstream', class_name: 'ActiveFedora::QualifiedDublinCoreDatastream'
    end
    class Bar < ActiveFedora::Base
      has_subresource 'barstream', class_name: 'MyDS'
    end
  end

  it "doesn't overwrite stream specs" do
    f = Foo.new
    expect(f.attached_files.size).to eq 2
    streams = f.attached_files.values.map { |x| x.class.to_s }.sort
    expect(streams.pop).to eq "MyDS"
    expect(streams.pop).to eq "ActiveFedora::QualifiedDublinCoreDatastream"
  end

  after do
    Object.send(:remove_const, :Bar)
    Object.send(:remove_const, :Foo)
    Object.send(:remove_const, :MyDS)
  end
end
