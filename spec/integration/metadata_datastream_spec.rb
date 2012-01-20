require 'spec_helper'

describe ActiveFedora::MetadataDatastream do

  describe "changing the controlGroup of a datastream" do
    before :all do
      class Foo < ActiveFedora::Base
        has_metadata :name => "stuff", :type => ActiveFedora::MetadataDatastream do |m|
          m.field "alt_title", :string
        end
      end
      obj = Foo.new()
      obj.stuff.update_indexed_attributes({ [:alt_title] => {"0" => "Title"}} ) 
      obj.save

      #Update the object
      obj2 = Foo.find(obj.pid)
      obj2.stuff.controlGroup = 'M'
      obj2.save

      @obj = Foo.find(obj.pid)
    end

    after :all do
      Object.send(:remove_const, :Foo)
    end

    it "should not change the datastream content" do
      @obj.stuff.alt_title_values.should == ['Title']
    end
  end
  describe "updating a datastream's content" do
    before :all do
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

    after :all do
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
