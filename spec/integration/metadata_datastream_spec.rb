require 'spec_helper'

describe ActiveFedora::MetadataDatastream do

  describe "when updating one datastream" do
    before do
      class Foo < ActiveFedora::Base
        has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
          m.field "field1",  :string
        end
        has_metadata :name => "stuff", :type => ActiveFedora::MetadataDatastream do |m|
          m.field "alt_title", :string
        end
      end
      obj = Foo.new()
      obj.properties.update_indexed_attributes({ [:field1] => {"0" => "test value"}} ) 
      obj.stuff.update_indexed_attributes({ [:alt_title] => {"0" => "Title"}} ) 
      obj.save

      #Update the object
      obj2 = Foo.find(obj.pid)
      obj2.stuff.update_indexed_attributes({ [:alt_title] => {"0" => "Moo Cow"}} )
      obj2.save

      @obj = Foo.find(obj.pid)
    end

    after do
      Object.send(:remove_const, :Foo)
    end

    it "should have updated the one datastream" do
      @obj.stuff.alt_title_values.should == ['Moo Cow']
    end
    it "should not have changed the other datastream" do
      @obj.properties.field1_values.should == ['test value']
    end
  end
end
