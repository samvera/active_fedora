require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class MyDS < ActiveFedora::File
    end

    class MySample < ActiveFedora::File
    end

    class Foo < ActiveFedora::Base
      has_subresource 'foostream', class_name: 'MyDS'
      has_subresource 'dcstream', class_name: 'MySample'
    end

    class Bar < ActiveFedora::Base
      has_subresource 'barstream', class_name: 'MyDS'
    end
  end

  subject(:attached_files) { f.attached_files }
  let(:f) { Foo.new }

  it "doesn't overwrite stream specs" do
    expect(attached_files.values).to match_array [MyDS, MySample]
  end

  after do
    Object.send(:remove_const, :Bar)
    Object.send(:remove_const, :Foo)
    Object.send(:remove_const, :MyDS)
    Object.send(:remove_const, :MySample)
  end
end
