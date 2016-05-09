require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Foo < ActiveFedora::Base
      extend Deprecation
      Deprecation.silence(Foo) do
        has_metadata "foostream", type: ActiveFedora::SimpleDatastream do |m|
          m.field "foostream", :string
        end
        has_metadata 'dcstream', type: ActiveFedora::QualifiedDublinCoreDatastream
      end
    end
    class Bar < ActiveFedora::Base
      extend Deprecation
      Deprecation.silence(Bar) do
        has_metadata 'barstream', type: ActiveFedora::SimpleDatastream do |m|
          m.field "barfield", :string
        end
      end
    end
  end

  it "doesn't overwrite stream specs" do
    f = Foo.new
    expect(f.attached_files.size).to eq 2
    streams = f.attached_files.values.map { |x| x.class.to_s }.sort
    expect(streams.pop).to eq "ActiveFedora::SimpleDatastream"
    expect(streams.pop).to eq "ActiveFedora::QualifiedDublinCoreDatastream"
  end

  it "works for multiple types" do
    b = Foo.new
    f = Bar.new
    Deprecation.silence(Foo) do
      Deprecation.silence(Bar) do
        expect(b.class.ds_specs).to_not eq f.class.ds_specs
      end
    end
  end

  after do
    Object.send(:remove_const, :Bar)
    Object.send(:remove_const, :Foo)
  end
end
