require 'spec_helper'

describe "When two or more relationships share the same property" do
  before do
    class Book < ActiveFedora::Base
      has_many :collections, :property=>:is_part_of, :class_name=>'Collection'
      has_many :people, :property=>:is_part_of
    end

    class Person < ActiveFedora::Base
      belongs_to :book, :property=>:is_part_of
    end

    class Collection < ActiveFedora::Base
      belongs_to :book, :property=>:is_part_of
    end

    @book = Book.create!
    @person1 = Person.create!(:book=>@book)
    @person2 = Person.create!(:book=>@book)
  end
  after do
      Object.send(:remove_const, :Collection)
      Object.send(:remove_const, :Person)
      Object.send(:remove_const, :Book)
  end

  it "Should only return relationships of the correct class" do
    @book.reload
    expect(@book.people).to eq([@person1, @person2])
    expect(@book.collections).to eq([])
  end
end

describe "When relationship is restricted to AF::Base" do
  before do
    class Email < ActiveFedora::Base
      has_many :attachments, :property=>:is_part_of, :class_name=>'ActiveFedora::Base'
    end

    class Image < ActiveFedora::Base
      belongs_to :email, :property=>:is_part_of
    end

    class PDF < ActiveFedora::Base
      belongs_to :email, :property=>:is_part_of
    end

    @book = Email.create!
    @image = Image.create!(:email=>@book)
    @pdf = PDF.create!(:email=>@book)
  end

  after do
      Object.send(:remove_const, :Image)
      Object.send(:remove_const, :PDF)
      Object.send(:remove_const, :Email)
  end

  it "Should not restrict relationships " do
    @book.reload
    expect(@book.attachments).to eq([@image, @pdf])
  end
end
