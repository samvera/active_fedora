require 'spec_helper'

describe "NestedAttribute behavior" do
  before do
    class Bar < ActiveFedora::Base
      belongs_to :foo, :property=>:has_member
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"someData" do |m|
        m.field "uno", :string
        m.field "dos", :string
      end
      delegate :uno, :to=>'someData', :unique=>true
      delegate :dos, :to=>'someData', :unique=>true
    end
    class Foo < ActiveFedora::Base
      has_many :bars, :property=>:has_member
      accepts_nested_attributes_for :bars#, :allow_destroy=>true
    end

    @foo = Foo.new
    @foo.save
    @bar1 = Bar.new(:foo=>@foo)
    @bar1.save

    @bar2 = Bar.new(:foo=>@foo)
    @bar2.save

  end

  it "should update the child objects" do
    @foo.attributes = {:bars_attributes=>[{:id=>@bar1.pid, :uno=>"bar1 uno"}, {:uno=>"newbar uno"}, {:id=>@bar2.pid, :_destroy=>'1', :uno=>'bar2 uno'}]}
    Bar.find(@bar1.pid).uno.should == 'bar1 uno'
    # pending the fix of nested_attributes_options
    #Bar.find(@bar2.pid).should be_nil

  end

    


end
