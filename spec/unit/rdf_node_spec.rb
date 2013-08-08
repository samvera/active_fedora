require 'spec_helper'

describe ActiveFedora::RdfNode do
  describe "inheritance" do
    before do
      class Parent
        include ActiveFedora::RdfObject
        map_predicates do |map|
          map.title(in: RDF::DC)
        end
      end

      class Child < Parent
        map_predicates do |map|
          map.description(in: RDF::DC)
        end
      end

    end
    after do
      Object.send(:remove_const, :Child)
      Object.send(:remove_const, :Parent)
    end

    describe "child class" do
      it "should inherit the terms" do
        Child.config.keys.should == ['title', 'description']
      end
    end
    describe "parent class" do
      it "should not be infected with the child terms" do
        Parent.config.keys.should == ['title']
      end
    end
  end
end
