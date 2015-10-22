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

  let!(:model1) { SpecModel::Basic.create! }
  let!(:model2) { SpecModel::Basic.create! }

  before do
    SpecModel::Basic.callback_counter = 0
  end

  describe ".destroy_all" do
    it "removes both and run callbacks" do
      SpecModel::Basic.destroy_all
      expect(SpecModel::Basic.count).to eq 0
      expect(SpecModel::Basic.callback_counter).to eq 2
    end

    describe "when a model is missing" do
      let(:model3) { SpecModel::Basic.create! }
      let!(:id) { model3.id }

      before { Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, model3.uri).delete }

      after do
        ActiveFedora::SolrService.instance.conn.tap do |conn|
          conn.delete_by_query "id:\"#{id}\""
          conn.commit
        end
      end

      it "is able to skip a missing model" do
        expect(described_class.logger).to receive(:error).with("Although #{id} was found in Solr, it doesn't seem to exist in Fedora. The index is out of synch.")
        SpecModel::Basic.destroy_all
        expect(SpecModel::Basic.count).to eq 1
      end
    end
  end

  describe ".delete_all" do
    it "removes both and not run callbacks" do
      SpecModel::Basic.delete_all
      expect(SpecModel::Basic.count).to eq 0
      expect(SpecModel::Basic.callback_counter).to eq 0
    end
  end
end
