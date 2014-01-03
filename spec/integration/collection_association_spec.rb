require 'spec_helper'

describe ActiveFedora::Base do
  before do
    class Library < ActiveFedora::Base 
      has_many :books, property: :has_member
    end
    class Book < ActiveFedora::Base; end
  end
  after do
    Object.send(:remove_const, :Library)
    Object.send(:remove_const, :Book)
  end
  describe "load_from_solr" do
    before do
      @library = Library.create
      3.times { @library.books << Book.create }
      @books = double(@library.books)
    end
    after do
      @library.books.each { |b| b.delete }
      @library.delete
    end
    it "should set rows to count, if not specified" do
      @library.books(response_format: :solr).size.should == 3
    end
    it "should limit rows returned if option passed" do
      @library.books(response_format: :solr, rows: 1).size.should == 1
    end
  end
end
