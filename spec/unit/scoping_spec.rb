require 'spec_helper'

describe ActiveFedora::Scoping::Default do
  describe "when default_scope is overridden" do
    before do
      class Book < ActiveFedora::Base
        property :published, predicate: ::RDF::Vocab::EBUCore.pubStatus do |index|
          index.as :symbol
        end

        def self.default_scope
          where published_ssim: 'true'
        end
      end

      Book.destroy_all
      Book.create!(published: [true])
      Book.create!(published: [true])
      Book.create!(published: [false])
    end

    after do
      Object.send(:remove_const, :Book)
    end

    it "returns only the scoped records" do
      expect(Book.all.size).to eq 2
    end

    it "returns all the records" do
      Book.unscoped do
        expect(Book.all.size).to eq 3
      end
    end
  end

  describe "when default_scope is called" do
    before do
      class Book < ActiveFedora::Base
        property :published, predicate: ::RDF::Vocab::EBUCore.pubStatus do |index|
          index.as :symbol
        end

        default_scope -> { where published_ssim: 'true' }
      end

      Book.destroy_all
      Book.create!(published: [true])
      Book.create!(published: [true])
      Book.create!(published: [false])
    end

    after do
      Object.send(:remove_const, :Book)
    end

    it "returns only the scoped records" do
      expect(Book.all.size).to eq 2
    end

    it "returns all the records" do
      Book.unscoped do
        expect(Book.all.size).to eq 3
      end
    end
  end
end
