require 'spec_helper'

describe "Marshalling and loading" do
  before do
    class Post < ActiveFedora::Base
      has_many :comments
      property :text, predicate: ::RDF::URI('http://example.com/text')
    end

    class Comment < ActiveFedora::Base
      belongs_to :post, predicate: ::RDF::URI('http://example.com/post')
    end
  end

  after do
    Object.send(:remove_const, :Post)
    Object.send(:remove_const, :Comment)
  end

  context "persisted records" do
    let(:post) { Post.create(text: ['serialize me']) }
    it "marshals them" do
      marshalled = Marshal.dump(post)
      loaded     = Marshal.load(marshalled)

      expect(loaded.attributes).to eq post.attributes
    end
  end

  context "with associations" do
    let(:post) { Post.create(comments: [Comment.new]) }
    it "marshals associations" do
      marshalled = Marshal.dump(post)
      loaded     = Marshal.load(marshalled)

      expect(loaded.comments.size).to eq 1
    end
  end
end
