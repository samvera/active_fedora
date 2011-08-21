require 'spec_helper'

describe "NestedAttribute behavior" do
  before do
    class Bar < ActiveFedora::Base
      belongs_to :car, :property=>:has_member
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"someData" do |m|
        m.field "uno", :string
        m.field "dos", :string
      end
      delegate :uno, :to=>'someData', :unique=>true
      delegate :dos, :to=>'someData', :unique=>true
    end
    class Car < ActiveFedora::Base
      has_many :bars, :property=>:has_member
      accepts_nested_attributes_for :bars#, :allow_destroy=>true
    end

    @car = Car.new
    @car.save
    @bar1 = Bar.new(:car=>@car)
    @bar1.save

    @bar2 = Bar.new(:car=>@car)
    @bar2.save

  end

  it "should update the child objects" do
    @car.attributes = {:bars_attributes=>[{:id=>@bar1.pid, :uno=>"bar1 uno"}, {:uno=>"newbar uno"}, {:id=>@bar2.pid, :_destroy=>'1', :uno=>'bar2 uno'}]}
    Bar.find(@bar1.pid).uno.should == 'bar1 uno'
    # pending the fix of nested_attributes_options
    #Bar.find(@bar2.pid).should be_nil

  end

    


end
