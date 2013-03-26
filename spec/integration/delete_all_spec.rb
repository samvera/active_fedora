require 'spec_helper'

describe ActiveFedora::Base do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
        class_attribute :callback_counter
        
        before_destroy :inc_counter

        def inc_counter
          self.class.callback_counter += 1
        end
      end
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end

  before do
    SpecModel::Basic.create!
    SpecModel::Basic.create!
    SpecModel::Basic.callback_counter = 0
  end


  describe ".destroy_all" do
    it "should remove both and run callbacks" do 
      SpecModel::Basic.destroy_all
      SpecModel::Basic.count.should == 0 
      SpecModel::Basic.callback_counter.should == 2
    end

  end

  describe ".delete_all" do
    it "should remove both and not run callbacks" do 
      SpecModel::Basic.delete_all
      SpecModel::Basic.count.should == 0
      SpecModel::Basic.callback_counter.should == 0
    end
  end
end
