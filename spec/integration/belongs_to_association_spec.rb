require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Library < ActiveFedora::Base 
      has_many :books
    end

    class Book < ActiveFedora::Base 
      belongs_to :library, :property=>:has_constituent
    end
  end
  after do
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end

  let(:library) { Library.create }
  let(:book) { Book.new }

  it "should allow setting the id property" do
    book.library_id = library.id
    book.library_id.should == library.id
  end

  it "should allow setting the id property via []=" do
    book[:library_id] = library.id
    book.library_id.should == library.id
  end

  it "should get the property id via []" do
    book[:library_id] = library.id
    book[:library_id].should == library.id
  end
end


