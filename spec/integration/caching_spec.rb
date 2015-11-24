require 'spec_helper'

describe "Caching" do
  before do
    class TestClass < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title
    end
  end

  after { Object.send(:remove_const, :TestClass) }

  let!(:object) { TestClass.create(id: '123') }

  describe "#cache" do
    it "finds records in the cache" do
      expect_any_instance_of(Faraday::Connection).to receive(:get).once.and_call_original
      ActiveFedora::Base.cache do
        o1 = TestClass.find(object.id)
        o2 = TestClass.find(object.id)
        expect(o1.ldp_source.get.body.object_id).to eq o2.ldp_source.get.body.object_id
      end
    end

    it "clears the cache at the end of the block" do
      expect_any_instance_of(Faraday::Connection).to receive(:get).twice.and_call_original
      ActiveFedora::Base.cache do
        TestClass.find(object.id)
      end
      ActiveFedora::Base.cache do
        TestClass.find(object.id)
      end
    end

    context "an update" do
      it "flushes the cache" do
        expect_any_instance_of(Faraday::Connection).to receive(:get).twice.and_call_original
        ActiveFedora::Base.cache do
          TestClass.find(object.id)
          object.title = ['foo']
          object.save!
          TestClass.find(object.id)
        end
      end
    end
  end

  describe "#uncached" do
    it "does not use the cache" do
      expect_any_instance_of(Faraday::Connection).to receive(:get).twice.and_call_original
      ActiveFedora::Base.cache do
        TestClass.find(object.id)
        ActiveFedora::Base.uncached do
          TestClass.find(object.id)
        end
        TestClass.find(object.id)
      end
    end
  end
end
