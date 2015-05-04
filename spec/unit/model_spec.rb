require 'spec_helper'
require 'action_controller'

describe ActiveFedora::Model do
  
  before(:all) do
    module SpecModel
      class Basic < ActiveFedora::Base
      end

      class Title < ActiveFedora::Base
        belongs_to :work, predicate: ::RDF::Vocab::Bibframe.relatedTo, class_name: 'SpecModel::Work'
        property :value, predicate: ::RDF::Vocab::Bibframe.titleValue, multiple: false
        property :variant, predicate: ::RDF::Vocab::Bibframe.titleType, multiple: false
        property :subtitle, predicate: ::RDF::Vocab::Bibframe.subtitle, multiple: false
      end

      class Work < ActiveFedora::Base
        has_many :titles, class_name: 'SpecModel::Title'
        accepts_nested_attributes_for :titles
      end
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :SpecModel)
  end
  
  describe '.solr_query_handler' do
    subject { SpecModel::Basic.solr_query_handler }
    after do
      # reset to default
      SpecModel::Basic.solr_query_handler = 'standard'
    end

    it { should eq 'standard' }

    context "when setting to something besides the default" do
      before { SpecModel::Basic.solr_query_handler = 'search' }

      it { should eq 'search' }
    end
  end

  describe ".from_class_uri" do
    subject { ActiveFedora::Model.from_class_uri(uri) }
    context "a blank string" do
      before { expect(ActiveFedora::Base.logger).to receive(:warn) }
      let(:uri) { '' }
      it { should be_nil }
    end
  end

  describe 'Nested titles' do

    it 'should only contain one title when saved with ActionController::Parameters' do
      SpecModel::Title.create(value: 'One fine title')
      SpecModel::Title.create(value: 'Another fine title')
      params = ActionController::Parameters.new(
          {
              "utf8"=>"✓", "authenticity_token"=>"4shDs/q9nxha/xSFgvHMOrfv8gPC81muvpsQ+uWvgkek2+9Y2gPmi/YSIYI9sxOZIXKOh3I2WBRBOHkoyQc1/A==",
              "work"=>{"titles_attributes"=>{"0"=>{"value"=>"A mediocre title" }}},
              "commit"=>"Gem værk", "controller"=>"works", "action"=>"create"
          }
      )
      permitted = params[:work].permit(titles_attributes: [[ :language ]])
      w = SpecModel::Work.new(permitted)
      expect(w.save).to be true
      expect(w.titles.size).to eql 1
    end

    it 'should only contain one title when saved with a hash of parameters' do
      SpecModel::Title.create(value: 'One fine title')
      SpecModel::Title.create(value: 'Another fine title')
      params = {"titles_attributes"=>{"0"=>{"value"=>"A mediocre title" }}}
      w = SpecModel::Work.new(params)
      expect(w.save).to be true
      expect(w.titles.size).to eql 1
    end
  end
end
