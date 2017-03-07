require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class MyDS < ActiveFedora::File
    end

    class MySample < ActiveFedora::File
    end

    class MyDeepSample < MySample
    end

    class Foo < ActiveFedora::Base
      has_subresource 'foostream', class_name: 'MyDS'
      has_subresource 'dcstream', class_name: 'MySample'
    end

    class Bar < ActiveFedora::Base
      has_subresource 'barstream', class_name: 'MyDS'
    end

    class Baz < Bar
    end
  end

  subject(:attached_files) { f.attached_files }
  let(:f) { Foo.new }

  it "doesn't overwrite stream specs" do
    expect(attached_files.values).to match_array [MyDS, MySample]
  end

  context 'base_class' do
    it 'shallow < Base' do
      expect(Bar.base_class).to eq(Bar)
    end

    it 'deep < Base' do
      expect(Baz.base_class).to eq(Bar)
    end

    it 'shallow < File' do
      expect(MySample.base_class).to eq(ActiveFedora::File)
    end

    it 'deep < File' do
      expect(MyDeepSample.base_class).to eq(ActiveFedora::File)
    end
  end

  after do
    Object.send(:remove_const, :Baz)
    Object.send(:remove_const, :Bar)
    Object.send(:remove_const, :Foo)
    Object.send(:remove_const, :MyDS)
    Object.send(:remove_const, :MyDeepSample)
    Object.send(:remove_const, :MySample)
  end
end
